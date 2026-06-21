import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Service Category ──────────────────────────────────────────────────────────
class ServiceCategory {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String description;
  final int serviceCount;

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    required this.serviceCount,
  });

  /// Professional Material icon for this category, used in place of the
  /// raw emoji string for a consistent, polished look across the app.
  IconData get iconData => categoryIconFor(name);

  /// Single, consistent brand color for every category icon. Previously
  /// each category had its own hex color (blue, green, orange, maroon...)
  /// which made the icon grid look mismatched. All category icons now
  /// share one color so the app looks consistent everywhere.
  Color get iconColor => categoryColorFor(name);
}

/// Consistent brand color used for every category icon across the app.
/// Centralized here so changing the app's icon color only requires one
/// edit, and every screen stays in sync automatically.
Color categoryColorFor(String categoryName) => AppTheme.primary;

/// Resolves a category name to a professional Material icon.
/// Falls back to a generic "build" icon for unknown categories.
IconData categoryIconFor(String categoryName) {
  switch (categoryName) {
    case 'Cleaning':
      return Icons.cleaning_services_rounded;
    case 'Plumbing':
      return Icons.plumbing_rounded;
    case 'Electrical':
      return Icons.electrical_services_rounded;
    case 'Painting':
      return Icons.format_paint_rounded;
    case 'Carpentry':
      return Icons.carpenter_rounded;
    case 'AC Service':
      return Icons.ac_unit_rounded;
    case 'Pest Control':
      return Icons.pest_control_rounded;
    case 'Appliances':
      return Icons.kitchen_rounded;
    case 'Gardening':
      return Icons.yard_rounded;
    case 'Home Shifting':
      return Icons.local_shipping_rounded;
    case 'CCTV Installation':
      return Icons.videocam_rounded;
    case 'Water Purifier':
      return Icons.water_drop_rounded;
    case 'Home Renovation':
      return Icons.home_repair_service_rounded;
    case 'Gym Training':
      return Icons.fitness_center_rounded;
    case 'Beauty Services':
      return Icons.face_retouching_natural_rounded;
    case 'Car Wash':
      return Icons.local_car_wash_rounded;
    default:
      return Icons.build_rounded;
  }
}

// ── Service Provider ──────────────────────────────────────────────────────────
class ServiceProvider {
  final String id;
  final String name;
  final String category;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final double pricePerHour;
  final bool isVerified;
  final bool isAvailable;
  final String location;
  final List<String> specializations;
  final int completedJobs;
  final String? email;
  final String? phone;

  const ServiceProvider({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.pricePerHour,
    required this.isVerified,
    required this.isAvailable,
    required this.location,
    required this.specializations,
    required this.completedJobs,
    this.email,
    this.phone,
  });

  factory ServiceProvider.fromFirestore(Map<String, dynamic> data, String id) {
    return ServiceProvider(
      id: id,
      name: data['name'] ?? '',
      category: data['serviceCategory'] ?? data['category'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['totalReviews'] ?? data['reviewCount'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      pricePerHour: (data['servicePrice'] ?? data['pricePerHour'] ?? 0).toDouble(),
      isVerified: data['isVerified'] ?? false,
      isAvailable: data['isAvailable'] ?? true,
      location: data['location'] ?? '',
      specializations: List<String>.from(data['specializations'] ?? []),
      completedJobs: data['completedJobs'] ?? 0,
      email: data['email'],
      phone: data['phone'],
    );
  }
}

// ── Booking ───────────────────────────────────────────────────────────────────
class Booking {
  final String id;
  final String serviceType;
  final String providerName;
  final String providerImage;
  final DateTime scheduledDate;
  final String status;
  final double amount;
  final String address;
  final String? notes;
  final String? providerId;
  final String? userId;
  final String? customerName;
  final String? listingId;
  final bool isRated;
  // Separate from [isRated] (which tracks the customer-rates-provider
  // review) — tracks whether the PROVIDER has rated the CUSTOMER for this
  // booking yet, so that flow can't be repeated either.
  final bool isCustomerRated;

  const Booking({
    required this.id,
    required this.serviceType,
    required this.providerName,
    required this.providerImage,
    required this.scheduledDate,
    required this.status,
    required this.amount,
    required this.address,
    this.notes,
    this.providerId,
    this.userId,
    this.customerName,
    this.listingId,
    this.isRated = false,
    this.isCustomerRated = false,
  });

  factory Booking.fromFirestore(Map<String, dynamic> data, String id) {
    return Booking(
      id: id,
      serviceType: data['serviceType'] ?? data['serviceName'] ?? '',
      providerName: data['providerName'] ?? '',
      providerImage: data['providerImage'] ?? '',
      scheduledDate: data['scheduledDate'] != null
          ? (data['scheduledDate'] as Timestamp).toDate()
          : (data['bookingDate'] != null
              ? (data['bookingDate'] as Timestamp).toDate()
              : DateTime.now()),
      status: data['status'] ?? 'pending',
      amount: (data['amount'] ?? data['totalAmount'] ?? 0).toDouble(),
      address: data['address'] ?? '',
      notes: data['notes'],
      providerId: data['providerId'],
      userId: data['userId'],
      customerName: data['customerName'],
      listingId: data['listingId'],
      isRated: data['isRated'] ?? false,
      isCustomerRated: data['isCustomerRated'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'serviceType': serviceType,
        'providerName': providerName,
        'providerImage': providerImage,
        'scheduledDate': Timestamp.fromDate(scheduledDate),
        'status': status,
        'amount': amount,
        'address': address,
        if (notes != null) 'notes': notes,
        if (providerId != null) 'providerId': providerId,
        if (userId != null) 'userId': userId,
        if (customerName != null) 'customerName': customerName,
        if (listingId != null) 'listingId': listingId,
        'isRated': isRated,
        'isCustomerRated': isCustomerRated,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

// ── Review ────────────────────────────────────────────────────────────────────
class Review {
  final String id;
  final String bookingId;
  final String providerId;
  final String? listingId;
  final String userId;
  final String userName;
  final double rating; // 1.0–5.0
  final String comment;
  final DateTime? createdAt;

  const Review({
    required this.id,
    required this.bookingId,
    required this.providerId,
    this.listingId,
    required this.userId,
    required this.userName,
    required this.rating,
    this.comment = '',
    this.createdAt,
  });

  factory Review.fromFirestore(Map<String, dynamic> data, String id) {
    return Review(
      id: id,
      bookingId: data['bookingId'] ?? '',
      providerId: data['providerId'] ?? '',
      listingId: data['listingId'],
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'bookingId': bookingId,
        'providerId': providerId,
        if (listingId != null) 'listingId': listingId,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      };
}


class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final List<String> addresses;
  final double rating;
  final int reviewCount;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.addresses,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  bool get isServiceProvider => role == 'service_provider';

  factory AppUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? 'user',
      addresses: List<String>.from(data['addresses'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['totalReviews'] ?? data['reviewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'addresses': addresses,
      };
}

// ── Service Listing ───────────────────────────────────────────────────────────
class ServiceListing {
  final String id;
  final String providerId;
  final String providerName;
  final String providerPhone;   // ← NEW: provider ka phone number
  final String providerLocation; // ← NEW: provider ki location
  final String title;
  final String description;
  final String category;
  final double price;
  final String priceUnit;
  final int durationMinutes;
  final bool isActive;
  final double rating;
  final int reviewCount;
  final DateTime? createdAt;
  // Editable by the provider in Add/Edit Listing. Falls back to a sensible
  // default list (see [defaultWhatsIncluded]) when empty, so older listings
  // created before this field existed still show something reasonable.
  final List<String> whatsIncluded;

  const ServiceListing({
    required this.id,
    required this.providerId,
    required this.providerName,
    this.providerPhone = '',
    this.providerLocation = '',
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.priceUnit,
    required this.durationMinutes,
    this.isActive = true,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.createdAt,
    this.whatsIncluded = const [],
  });

  factory ServiceListing.fromFirestore(Map<String, dynamic> data, String id) {
    return ServiceListing(
      id: id,
      providerId: data['providerId'] ?? '',
      providerName: data['providerName'] ?? '',
      providerPhone: data['providerPhone'] ?? '',
      providerLocation: data['providerLocation'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      priceUnit: data['priceUnit'] ?? 'per visit',
      durationMinutes: data['durationMinutes'] ?? 60,
      isActive: data['isActive'] ?? true,
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      whatsIncluded: data['whatsIncluded'] != null
          ? List<String>.from(data['whatsIncluded'])
          : const [],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'providerId': providerId,
        'providerName': providerName,
        'providerPhone': providerPhone,
        'providerLocation': providerLocation,
        'title': title,
        'description': description,
        'category': category,
        'price': price,
        'priceUnit': priceUnit,
        'durationMinutes': durationMinutes,
        'isActive': isActive,
        'rating': rating,
        'reviewCount': reviewCount,
        'whatsIncluded': whatsIncluded,
        'createdAt': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> toUpdateMap() => {
        'title': title,
        'description': description,
        'category': category,
        'price': price,
        'priceUnit': priceUnit,
        'durationMinutes': durationMinutes,
        'isActive': isActive,
        'providerPhone': providerPhone,
        'providerLocation': providerLocation,
        'whatsIncluded': whatsIncluded,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  ServiceListing copyWith({
    String? title,
    String? description,
    String? category,
    double? price,
    String? priceUnit,
    int? durationMinutes,
    bool? isActive,
    String? providerPhone,
    String? providerLocation,
    List<String>? whatsIncluded,
  }) {
    return ServiceListing(
      id: id,
      providerId: providerId,
      providerName: providerName,
      providerPhone: providerPhone ?? this.providerPhone,
      providerLocation: providerLocation ?? this.providerLocation,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      priceUnit: priceUnit ?? this.priceUnit,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isActive: isActive ?? this.isActive,
      rating: rating,
      reviewCount: reviewCount,
      createdAt: createdAt,
      whatsIncluded: whatsIncluded ?? this.whatsIncluded,
    );
  }

  /// Default checklist shown when a provider hasn't customized
  /// "What's included" for this listing yet (e.g. older listings created
  /// before this field existed, or a new listing where the provider left
  /// it untouched).
  static List<String> defaultWhatsIncluded(int durationMinutes) => [
        'Professional tools & equipment',
        'Trained and verified expert',
        '${_formatDurationStatic(durationMinutes)} of dedicated service',
        'Post-service quality check',
      ];

  static String _formatDurationStatic(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h hr' : '$h hr $m min';
  }
}

// ── Static Data ───────────────────────────────────────────────────────────────
class MockData {
  static const List<ServiceCategory> categories = [
    ServiceCategory(id: '1', name: 'Cleaning', icon: '🧹', color: '#0A84FF', description: 'Deep & regular cleaning', serviceCount: 42),
    ServiceCategory(id: '2', name: 'Plumbing', icon: '🔧', color: '#00C2E0', description: 'Repairs & installations', serviceCount: 28),
    ServiceCategory(id: '3', name: 'Electrical', icon: '⚡', color: '#0066CC', description: 'Wiring & fixtures', serviceCount: 35),
    ServiceCategory(id: '4', name: 'Painting', icon: '🎨', color: '#4DD9EC', description: 'Interior & exterior', serviceCount: 19),
    ServiceCategory(id: '5', name: 'Carpentry', icon: '🪚', color: '#003F88', description: 'Furniture & fixtures', serviceCount: 24),
    ServiceCategory(id: '6', name: 'AC Service', icon: '❄️', color: '#00B4D8', description: 'Repair & maintenance', serviceCount: 31),
    ServiceCategory(id: '7', name: 'Pest Control', icon: '🐛', color: '#0077B6', description: 'Home & garden', serviceCount: 15),
    ServiceCategory(id: '8', name: 'Appliances', icon: '🔌', color: '#48CAE4', description: 'Repair & installation', serviceCount: 38),
    // ✅ NEW 8 Categories - Total 16
    ServiceCategory(id: '9', name: 'Gardening', icon: '🌿', color: '#2E7D32', description: 'Lawn & garden care', serviceCount: 12),
    ServiceCategory(id: '10', name: 'Home Shifting', icon: '🚚', color: '#E65100', description: 'Packing & moving', serviceCount: 18),
    ServiceCategory(id: '11', name: 'CCTV Installation', icon: '📹', color: '#1A237E', description: 'Security cameras', serviceCount: 22),
    ServiceCategory(id: '12', name: 'Water Purifier', icon: '💧', color: '#00695C', description: 'RO repair & service', serviceCount: 14),
    ServiceCategory(id: '13', name: 'Home Renovation', icon: '🏗️', color: '#4E342E', description: 'Interior renovation', serviceCount: 20),
    ServiceCategory(id: '14', name: 'Gym Training', icon: '💪', color: '#BF360C', description: 'Personal training', serviceCount: 16),
    ServiceCategory(id: '15', name: 'Beauty Services', icon: '💄', color: '#880E4F', description: 'Salon & makeup', serviceCount: 25),
    ServiceCategory(id: '16', name: 'Car Wash', icon: '🚗', color: '#0D47A1', description: 'Car detailing & wash', serviceCount: 30),
  ];
}
