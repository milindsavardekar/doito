import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

// ── Phone Normalization ───────────────────────────────────────────────────────
/// Normalizes any phone input into a consistent E.164-ish digit string
/// (last 10 digits, no spaces/dashes/+91), so the same number always maps
/// to the same key regardless of how it was typed/stored historically.
String normalizeMobile(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length <= 10) return digits;
  return digits.substring(digits.length - 10);
}

/// Formats a phone number into the full E.164 string Firebase Phone Auth
/// requires (e.g. "+918180919100"). Always assumes India (+91) for bare
/// 10-digit numbers — adjust the default country code here if you ever
/// need to support other countries.
String toE164(String raw) {
  final trimmed = raw.trim();
  if (trimmed.startsWith('+')) {
    // Already has a country code — just strip stray spaces/dashes.
    return '+${trimmed.substring(1).replaceAll(RegExp(r'[^0-9]'), '')}';
  }
  final tenDigits = normalizeMobile(trimmed);
  return '+91$tenDigits';
}

// ── Auth Service ──────────────────────────────────────────────────────────────
class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AppUser?> signUp(
      String email, String password, String name, String phone,
      {String role = 'user'}) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final user = AppUser(
      uid: cred.user!.uid,
      name: name,
      email: email,
      phone: phone,
      role: role,
      addresses: [],
    );
    await _db.collection('users').doc(cred.user!.uid).set({
      ...user.toFirestore(),
      'phoneKey': normalizeMobile(phone),
    });
    return user;
  }

  Future<User?> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return cred.user;
  }

  /// Signs out of Firebase Auth AND clears Firestore's local disk cache.
  ///
  /// Why this matters: cloud_firestore keeps a local persistence cache per
  /// device (not per account). If a second person logs into a different
  /// account on the same phone, `.snapshots()` listeners can briefly serve
  /// data that's still in that local cache from the previous account before
  /// the server catches up — e.g. a customer seeing the rating *they*
  /// submitted instead of another customer's, when both tested on the same
  /// device. Clearing the cache on every sign-out forces the next session
  /// to always read fresh from the server, avoiding this entirely.
  Future<void> signOut() async {
    // Terminate Firestore first to close all active listeners,
    // then sign out from Auth. clearPersistence is not needed here
    // and causes errors when listeners are still attached.
    try {
      await FirebaseFirestore.instance.terminate();
    } catch (_) {}
    await _auth.signOut();
  }

  Future<AppUser?> getUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromFirestore(doc.data()!, uid);
      }
    } catch (_) {}
    return null;
  }

  /// Updates a user's optional public-facing contact info (email and/or
  /// address). Both are optional — pass null to leave a field unchanged,
  /// or an empty string to explicitly clear it. Used by providers to fill
  /// in contact details shown on their public profile; customers booking
  /// a service never see this update flow.
  Future<void> updateUserContactInfo(
    String uid, {
    String? email,
    String? address,
  }) async {
    final updates = <String, dynamic>{};
    if (email != null) updates['email'] = email.trim();
    if (address != null) {
      updates['addresses'] = address.trim().isEmpty ? [] : [address.trim()];
    }
    if (updates.isEmpty) return;
    await _db.collection('users').doc(uid).set(updates, SetOptions(merge: true));
  }

  /// Finds a user doc by phone number (regardless of which auth uid it's
  /// currently keyed under). Used as a fallback when the OTP-auth uid has
  /// no matching doc — covers accounts originally created via the old
  /// email/password flow, or any other uid mismatch.
  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _findUserDocByPhone(
      String phone) async {
    final key = normalizeMobile(phone);
    if (key.isEmpty) return null;

    // Preferred: query by the indexed phoneKey field (works once migrated).
    final byKey = await _db
        .collection('users')
        .where('phoneKey', isEqualTo: key)
        .limit(1)
        .get();
    if (byKey.docs.isNotEmpty) return byKey.docs.first;

    // Fallback for older docs that predate phoneKey: scan by raw phone field.
    // (Small user bases only — fine as a one-time migration path.)
    final all = await _db.collection('users').get();
    for (final d in all.docs) {
      final storedPhone = (d.data()['phone'] ?? '').toString();
      if (normalizeMobile(storedPhone) == key) return d;
    }
    return null;
  }

  /// Role-aware lookup used right after OTP login/splash routing.
  ///
  /// 1. Try the doc at the current Firebase Auth uid (fast path — true for
  ///    every user created through the current OTP flow).
  /// 2. If missing, look up by phone number. If an older doc is found
  ///    under a different uid (e.g. created via the old email/password
  ///    flow), migrate it: copy it to the new uid, re-point any of that
  ///    provider's listings/bookings to the new uid, then remove the old
  ///    doc. This keeps role + existing data intact for the user.
  Future<AppUser?> resolveUserForLogin({
    required String uid,
    required String phone,
  }) async {
    final direct = await getUserData(uid);
    if (direct != null) return direct;

    final oldDoc = await _findUserDocByPhone(phone);
    if (oldDoc == null) return null;
    if (oldDoc.id == uid) {
      return AppUser.fromFirestore(oldDoc.data(), uid);
    }

    final oldUid = oldDoc.id;
    final data = Map<String, dynamic>.from(oldDoc.data());
    data['phoneKey'] = normalizeMobile(phone);
    data['phone'] = phone;
    data['migratedFromUid'] = oldUid;

    final batch = _db.batch();
    batch.set(_db.collection('users').doc(uid), data);
    batch.delete(_db.collection('users').doc(oldUid));
    await batch.commit();

    // Re-point this provider's listings and bookings so the new uid
    // can still see everything they created/received before.
    await _repointProviderId(oldUid: oldUid, newUid: uid);

    return AppUser.fromFirestore(data, uid);
  }

  Future<void> _repointProviderId({
    required String oldUid,
    required String newUid,
  }) async {
    final listings = await _db
        .collection('services')
        .where('providerId', isEqualTo: oldUid)
        .get();
    final bookingsAsProvider = await _db
        .collection('bookings')
        .where('providerId', isEqualTo: oldUid)
        .get();
    final bookingsAsUser = await _db
        .collection('bookings')
        .where('userId', isEqualTo: oldUid)
        .get();

    if (listings.docs.isEmpty &&
        bookingsAsProvider.docs.isEmpty &&
        bookingsAsUser.docs.isEmpty) {
      return;
    }

    final batch = _db.batch();
    for (final d in listings.docs) {
      batch.update(d.reference, {'providerId': newUid});
    }
    for (final d in bookingsAsProvider.docs) {
      batch.update(d.reference, {'providerId': newUid});
    }
    for (final d in bookingsAsUser.docs) {
      batch.update(d.reference, {'userId': newUid});
    }
    await batch.commit();
  }

  // ═══════════════════════════════════════════════════════════════
  // ── NEW: OTP Methods ──
  // ═══════════════════════════════════════════════════════════════

  // Send OTP
  Future<void> sendOTP({
    required String phoneNumber,
    required void Function(PhoneAuthCredential?) onVerificationCompleted,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String error) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Verification failed');
      },
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (String verificationId) {
        // Handle timeout
      },
    );
  }

  // Save user data with OTP
  Future<AppUser?> saveUserDataWithOTP({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String role,
  }) async {
    final user = AppUser(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
      role: role,
      addresses: [],
    );
    await _db.collection('users').doc(uid).set({
      ...user.toFirestore(),
      'phoneKey': normalizeMobile(phone),
    });
    return user;
  }

  Future<void> updateUserRole({
    required String uid,
    required String role,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': role});
  }
}

// ── Firestore Service ─────────────────────────────────────────────────────────
class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ── Categories ──
  /// Live stream of all active categories, ordered by name.
  /// Admin panel controls isActive — inactive ones are hidden from the app.
  Stream<List<ServiceCategory>> getCategories() {
    return _db
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => ServiceCategory.fromFirestore(d.data(), d.id))
          .toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  // ── Locations ──
  /// Live stream of selectable localities (e.g. "Sangli - Vishrambag"),
  /// managed from the admin panel's Locations page. Every location
  /// picker in the app should read through this (or [getLocationsOnce])
  /// instead of the old hardcoded `kSangliLocations` list, so adding or
  /// removing an area from the admin panel takes effect everywhere
  /// without an app update.
  Stream<List<String>> getLocations() {
    return _db
        .collection('locations')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => (d.data()['name'] ?? '') as String)
          .where((n) => n.isNotEmpty)
          .toList();
      list.sort();
      return list;
    });
  }

  /// One-time fetch (not a live stream) — used where a picker needs the
  /// list once synchronously, like a bottom-sheet location chooser,
  /// rather than staying subscribed for the lifetime of a modal.
  Future<List<String>> getLocationsOnce() async {
    final snap = await _db
        .collection('locations')
        .where('isActive', isEqualTo: true)
        .get();
    final list = snap.docs
        .map((d) => (d.data()['name'] ?? '') as String)
        .where((n) => n.isNotEmpty)
        .toList();
    list.sort();
    return list;
  }

  // ── Providers ──
  Stream<List<ServiceProvider>> getServiceProviders({String? category}) {
    var q = _db.collection('users').where('role', isEqualTo: 'service_provider');
    if (category != null && category != 'All') {
      q = q.where('serviceCategory', isEqualTo: category);
    }
    return q.snapshots().map((snap) => snap.docs
        .map((d) => ServiceProvider.fromFirestore(d.data(), d.id))
        .toList());
  }

  // ── Bookings ──
  Future<void> addBooking(Booking booking) =>
      _db.collection('bookings').add(booking.toFirestore());

  /// Bookings made by a customer
  Stream<List<Booking>> getUserBookings(String userId) {
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => Booking.fromFirestore(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
      return list;
    });
  }

  /// Bookings received by a provider
  Stream<List<Booking>> getProviderBookings(String providerId) {
    return _db
        .collection('bookings')
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => Booking.fromFirestore(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
      return list;
    });
  }

  Future<void> updateBookingStatus(String id, String status) =>
      _db.collection('bookings').doc(id).update({'status': status});

  // ── Service Listings ──

  /// All ACTIVE listings for customers — all filtering done client-side, zero index needed
  Stream<List<ServiceListing>> getServiceListings({String? category}) {
    return _db.collection('services').snapshots().map((snap) {
      var list = snap.docs
          .map((d) => ServiceListing.fromFirestore(d.data(), d.id))
          .toList();
      // filter: only active
      list = list.where((l) => l.isActive).toList();
      // filter: category
      if (category != null && category != 'All') {
        list = list.where((l) => l.category == category).toList();
      }
      // sort: newest first
      list.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return list;
    });
  }

  /// Provider's OWN listings — only filters by providerId, no index needed
  Stream<List<ServiceListing>> getMyListings(String providerId) {
    return _db
        .collection('services')
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => ServiceListing.fromFirestore(d.data(), d.id))
          .toList();
      list.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return list;
    });
  }

  Future<String> addServiceListing(ServiceListing listing) async {
    final ref = await _db.collection('services').add(listing.toFirestore());
    return ref.id;
  }

  Future<void> updateServiceListing(ServiceListing listing) =>
      _db.collection('services')
          .doc(listing.id)
          .update(listing.toUpdateMap());

  Future<void> toggleListingActive(String id, bool isActive) =>
      _db.collection('services').doc(id).update({'isActive': isActive});

  Future<void> deleteServiceListing(String id) =>
      _db.collection('services').doc(id).delete();

  // ── Reviews ──

  /// Submits a review for a completed booking and atomically updates the
  /// aggregate rating/reviewCount on the provider's user doc (and, if the
  /// booking is tied to a specific listing, on that listing too). Also
  /// marks the booking as rated so it can't be rated twice.
  Future<void> submitReview({
    required String bookingId,
    required String providerId,
    String? listingId,
    required String userId,
    required String userName,
    required double rating,
    String comment = '',
  }) async {
    final reviewRef = _db.collection('reviews').doc();
    final providerRef = _db.collection('users').doc(providerId);
    final bookingRef = _db.collection('bookings').doc(bookingId);
    final listingRef =
        listingId != null ? _db.collection('services').doc(listingId) : null;

    await _db.runTransaction((txn) async {
      // ── Reads first (Firestore transaction rule) ──
      final providerSnap = await txn.get(providerRef);
      final listingSnap = listingRef != null ? await txn.get(listingRef) : null;

      // ── Provider aggregate ──
      final providerData = providerSnap.data() ?? {};
      final prevProviderRating = (providerData['rating'] ?? 0.0).toDouble();
      final prevProviderCount =
          (providerData['totalReviews'] ?? providerData['reviewCount'] ?? 0)
              as int;
      final newProviderCount = prevProviderCount + 1;
      final newProviderRating =
          ((prevProviderRating * prevProviderCount) + rating) /
              newProviderCount;

      txn.set(
        providerRef,
        {
          'rating': newProviderRating,
          'totalReviews': newProviderCount,
        },
        SetOptions(merge: true),
      );

      // ── Listing aggregate (if this booking was for a specific listing) ──
      if (listingRef != null && listingSnap != null && listingSnap.exists) {
        final listingData = listingSnap.data() ?? {};
        final prevListingRating = (listingData['rating'] ?? 0.0).toDouble();
        final prevListingCount = (listingData['reviewCount'] ?? 0) as int;
        final newListingCount = prevListingCount + 1;
        final newListingRating =
            ((prevListingRating * prevListingCount) + rating) /
                newListingCount;

        txn.update(listingRef, {
          'rating': newListingRating,
          'reviewCount': newListingCount,
        });
      }

      // ── The review itself ──
      txn.set(reviewRef, {
        'bookingId': bookingId,
        'providerId': providerId,
        'listingId': ?listingId,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ── Lock the booking so it can't be rated again ──
      txn.update(bookingRef, {'isRated': true});
    });
  }

  /// Submits a PROVIDER's rating of a CUSTOMER for a completed booking.
  ///
  /// This is the mirror of [submitReview] but in the other direction, and
  /// deliberately kept in its own `customer_ratings` collection (instead of
  /// reusing `reviews`) so the two are trivially separable: nothing in the
  /// customer-facing UI ever queries `customer_ratings`, so a customer has
  /// no code path that could surface a rating left about them — only
  /// providers (via [getCustomerRatingSummary]) can see it, e.g. before
  /// deciding whether to accept a future booking from that customer.
  Future<void> submitCustomerRating({
    required String bookingId,
    required String customerId,
    required String providerId,
    required String providerName,
    required double rating,
    String comment = '',
  }) async {
    final ratingRef = _db.collection('customer_ratings').doc();
    final customerRef = _db.collection('users').doc(customerId);
    final bookingRef = _db.collection('bookings').doc(bookingId);

    await _db.runTransaction((txn) async {
      final customerSnap = await txn.get(customerRef);
      final customerData = customerSnap.data() ?? {};
      final prevRating = (customerData['customerRating'] ?? 0.0).toDouble();
      final prevCount = (customerData['customerRatingCount'] ?? 0) as int;
      final newCount = prevCount + 1;
      final newRating = ((prevRating * prevCount) + rating) / newCount;

      txn.set(
        customerRef,
        {
          'customerRating': newRating,
          'customerRatingCount': newCount,
        },
        SetOptions(merge: true),
      );

      txn.set(ratingRef, {
        'bookingId': bookingId,
        'customerId': customerId,
        'providerId': providerId,
        'providerName': providerName,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      txn.update(bookingRef, {'isCustomerRated': true});
    });
  }

  /// A customer's aggregate rating as left by providers — for providers'
  /// eyes only. Returns null if the customer hasn't been rated yet.
  Future<({double rating, int count})?> getCustomerRatingSummary(
      String customerId) async {
    final snap = await _db.collection('users').doc(customerId).get();
    final data = snap.data();
    if (data == null || data['customerRatingCount'] == null) return null;
    final count = (data['customerRatingCount'] ?? 0) as int;
    if (count == 0) return null;
    final double rating = (data['customerRating'] ?? 0.0).toDouble();
    return (rating: rating, count: count);
  }

  /// All reviews for a provider, newest first.
  Stream<List<Review>> getProviderReviews(String providerId) {
    return _db
        .collection('reviews')
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => Review.fromFirestore(d.data(), d.id))
          .toList();
      list.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return list;
    });
  }

  /// All ratings/comments left by providers about a specific customer,
  /// newest first. Lets a provider tap a customer's rating badge and see
  /// what other providers said about them (mirrors [getProviderReviews]).
  Stream<List<CustomerRating>> getCustomerRatings(String customerId) {
    return _db
        .collection('customer_ratings')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => CustomerRating.fromFirestore(d.data(), d.id))
          .toList();
      list.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return list;
    });
  }
}