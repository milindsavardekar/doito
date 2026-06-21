# Doito — Professional Home Services App
## Orange-Yellow Gradient Theme | Firebase Connected

---

## Project Structure
```
lib/
├── main.dart                    ← Entry point, Firebase init
├── firebase_options.dart        ← Your Firebase config (dailyserv-d65aa)
├── theme/app_theme.dart         ← Orange-Yellow brand theme
├── models/models.dart           ← All data models
├── services/firebase_services.dart  ← Auth + Firestore
├── widgets/common_widgets.dart  ← Reusable UI components
└── screens/
    ├── splash_screen.dart
    ├── auth/login_screen.dart
    ├── auth/register_screen.dart
    ├── home/main_screen.dart
    ├── home/home_screen.dart
    ├── explore/explore_screen.dart
    ├── services/service_detail_screen.dart
    ├── bookings/booking_screen.dart
    ├── bookings/bookings_list_screen.dart
    └── profile/profile_screen.dart
```

---

## Setup Steps

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Firebase is already connected
- Project ID: `dailyserv-d65aa`
- `google-services.json` is placed in `android/app/`
- `firebase_options.dart` is configured

### 3. Run
```bash
flutter run
```

---

## Firestore Data Structure

### Collection: `users`
```
users/{uid}
  name: string
  email: string
  phone: string
  role: "user" | "service_provider"
  addresses: string[]
  // For service providers:
  serviceCategory: string
  servicePrice: number
  rating: number
  totalReviews: number
  isAvailable: boolean
  isVerified: boolean
  location: string
  specializations: string[]
  completedJobs: number
  imageUrl: string
```

### Collection: `bookings`
```
bookings/{id}
  userId: string
  providerId: string
  serviceType: string
  providerName: string
  providerImage: string
  scheduledDate: timestamp
  status: "pending"|"confirmed"|"in_progress"|"completed"|"cancelled"
  amount: number
  address: string
  notes: string (optional)
  listingId: string (optional — which service listing this booking was for)
  isRated: boolean (default false — flips to true once the customer rates it)
  createdAt: timestamp
```

### Collection: `reviews`
```
reviews/{id}
  bookingId: string
  providerId: string
  listingId: string (optional)
  userId: string
  userName: string
  rating: number (1–5)
  comment: string
  createdAt: timestamp
```
Created by `submitReview()` in `firebase_services.dart` once a customer
rates a completed booking. The same call atomically updates the
aggregate `rating`/`totalReviews` on the provider's `users` doc, and
`rating`/`reviewCount` on the specific `services` listing if the
booking was tied to one.

---

## Firestore Rules (paste in Firebase Console)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read: if request.auth != null;

      // Normal case: a user can only write their own doc.
      allow create: if request.auth.uid == uid;

      // A user can fully update their own doc. Any OTHER signed-in user
      // may only touch the aggregate rating fields (this is how a
      // customer's review updates the provider's rating/totalReviews —
      // see submitReview() in firebase_services.dart). This is a
      // pragmatic client-side rule, not airtight: a malicious client
      // could in theory call this with a fabricated rating outside of
      // the normal review flow. If that risk matters for your use case,
      // move the aggregate-update logic into a Cloud Function triggered
      // on reviews/{id} create, and lock this down to uid-only writes.
      allow update: if request.auth != null && (
        request.auth.uid == uid ||
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['rating', 'totalReviews'])
      );

      // Migration case: deleting an OLD doc (created under a different
      // uid by the legacy email/password flow) is only allowed when the
      // signed-in user's verified phone number matches the phoneKey
      // stored on that old doc — i.e. you can only delete a record that
      // provably belongs to your own phone number.
      allow delete: if request.auth != null &&
        resource.data.phoneKey is string &&
        resource.data.phoneKey ==
          request.auth.token.phone_number.replace('[^0-9]', '')
            .replace('^91', '');
    }
    match /bookings/{id} {
      allow read, write: if request.auth != null;
    }
    match /services/{id} {
      allow read: if true;
      allow create, delete: if request.auth != null;
      // Allow the listing owner full updates, and any signed-in user to
      // touch only the rating/reviewCount fields (same reasoning as
      // above — driven by submitReview()).
      allow update: if request.auth != null && (
        request.auth.uid == resource.data.providerId ||
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['rating', 'reviewCount'])
      );
    }
    match /reviews/{id} {
      allow read: if true;
      // A user may only create a review attributed to themselves.
      allow create: if request.auth != null &&
        request.resource.data.userId == request.auth.uid;
      allow update, delete: if false;
    }
  }
}
```

> ⚠️ Firestore security rules don't support arbitrary string normalization
> like the app's `normalizeMobile()` does in Dart. If the `phone_number`
> regex match above isn't reliable for your data, the safer alternative
> is restricting the one-time migration logic to a Cloud Function /
> Admin SDK script instead of letting the client delete old docs
> directly — ask if you'd like that version instead.

---

## Theme Colors
| Color | Hex | Usage |
|-------|-----|-------|
| Primary | #FF6B00 | Deep Orange — main brand |
| Accent | #FFAB00 | Amber/Gold — highlights |
| Accent Light | #FFD54F | Light Yellow |
| Surface | #FFFBF5 | Warm white background |
| Success | #34C759 | Confirmed/Available |
| Error | #FF3B30 | Cancel/Error |
