import 'package:flutter/foundation.dart';
import 'firebase_services.dart';

/// Fallback list, only used if Firestore's `locations` collection hasn't
/// loaded yet (e.g. very first frame, or briefly offline). The real,
/// live source of truth is `FirestoreService().getLocations()` —
/// managed from the admin panel's Locations page. Screens should prefer
/// [LocationService.cached] (kept warm by [LocationService.warmCache])
/// over this constant wherever possible.
const List<String> kSangliLocations = [
  'Sangli - Yashwantnagar', 'Sangli - Madhavnagar', 'Sangli - Vijaynagar',
  'Sangli - Sangliwadi', 'Sangli - Miraj', 'Sangli - Gaonbhag',
  'Sangli - Khanbhag', 'Sangli - Ganeshnagar', 'Sangli - Kupwad',
  'Sangli - Bamani', 'Sangli - Bamnoli', 'Sangli - Vishrambag',
  'Sangli - Nalbhag', 'Sangli - Sanjaynagar', 'Sangli - Wanlesswadi',
  'Sangli - Shamraonagar', 'Sangli - Haripur Road', 'Sangli - Haripur',
  'Sangli - Rukmini Nagar', 'Sangli - Shastri Nagar', 'Sangli - Ashok Nagar',
  'Sangli - Shinde Nagar', 'Sangli - Dhanwantari Nagar', 'Sangli - Shivarampur',
  'Sangli - Harshwardhan Nagar', 'Sangli - Shivaji Nagar',
  'Sangli - Ganpati Nagar', 'Sangli - Dhamni',
];

/// App-wide selected location, shared by every screen.
///
/// Previously Home and Nearby each kept their own `_selectedLocation`
/// field, so picking a location on one screen had no effect on the
/// other. This singleton is the single source of truth: any screen that
/// listens to it (via [AnimatedBuilder]/[ValueListenableBuilder] or by
/// reading `.value`) sees the same selection, and changing it from any
/// screen updates every other screen immediately — no navigation or
/// restart required, since Home/Nearby/etc. all stay mounted together
/// inside the bottom-nav's IndexedStack.
class LocationService {
  LocationService._();
  static final ValueNotifier<String> selected =
      ValueNotifier<String>('Sangli - Vishrambag');

  /// Cached copy of the live Firestore location list, refreshed by
  /// [warmCache]. Bottom-sheet pickers read this synchronously so they
  /// open instantly instead of showing a loading flicker every time.
  /// Starts as [kSangliLocations] so the very first picker open (before
  /// [warmCache] has had a chance to finish) still shows something
  /// sensible rather than an empty list.
  static List<String> cached = List.of(kSangliLocations);

  /// Call once near app startup, and it's safe to call again any time
  /// (e.g. right before opening a location picker) to refresh [cached]
  /// from Firestore. Silently keeps the previous [cached] value if the
  /// fetch fails, so a picker never ends up empty just because of a
  /// brief network hiccup.
  static Future<void> warmCache() async {
    try {
      final live = await FirestoreService().getLocationsOnce();
      if (live.isNotEmpty) cached = live;
    } catch (_) {
      // Keep whatever was cached before (or the kSangliLocations
      // default) — better than leaving the picker with nothing.
    }
  }

  static void set(String location) {
    if (location.isNotEmpty) selected.value = location;
  }
}
