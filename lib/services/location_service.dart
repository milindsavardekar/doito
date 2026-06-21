import 'package:flutter/foundation.dart';

/// Canonical list of selectable localities — the single source of truth
/// used everywhere a location picker is shown (Home, Nearby, listing
/// creation), so every screen offers the exact same set of areas.
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

  static void set(String location) {
    if (location.isNotEmpty) selected.value = location;
  }
}
