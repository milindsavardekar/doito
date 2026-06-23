import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firebase_services.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../services/service_listing_detail_screen.dart';

// Localities grouped by proximity
const Map<String, List<String>> _nearbyMap = {
  'Sangli - Vishrambag': ['Sangli - Vishrambag', 'Sangli - Madhavnagar', 'Sangli - Nalbhag', 'Sangli - Sanjaynagar', 'Sangli - Gaonbhag', 'Sangli - Khanbhag'],
  'Sangli - Madhavnagar': ['Sangli - Madhavnagar', 'Sangli - Vishrambag', 'Sangli - Vijaynagar', 'Sangli - Sanjaynagar', 'Sangli - Nalbhag'],
  'Sangli - Miraj': ['Sangli - Miraj', 'Sangli - Kupwad', 'Sangli - Wanlesswadi', 'Sangli - Shivarampur'],
  'Sangli - Kupwad': ['Sangli - Kupwad', 'Sangli - Miraj', 'Sangli - Shivarampur'],
  'Sangli - Yashwantnagar': ['Sangli - Yashwantnagar', 'Sangli - Ashok Nagar', 'Sangli - Shastri Nagar', 'Sangli - Shivaji Nagar'],
  'Sangli - Gaonbhag': ['Sangli - Gaonbhag', 'Sangli - Khanbhag', 'Sangli - Vishrambag', 'Sangli - Nalbhag'],
  'Sangli - Nalbhag': ['Sangli - Nalbhag', 'Sangli - Vishrambag', 'Sangli - Gaonbhag', 'Sangli - Khanbhag'],
  'Sangli - Sanjaynagar': ['Sangli - Sanjaynagar', 'Sangli - Madhavnagar', 'Sangli - Vishrambag'],
};

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  final _firestore = FirestoreService();
  final _searchCtrl = TextEditingController();

  String get _selectedLocation => LocationService.selected.value;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _distanceFilter = 'All';

  // Cache the stream so it isn't re-subscribed on every setState/rebuild
  // (search typing, category taps, etc.) — only recreate it when the
  // category actually changes, since that's the only thing that affects
  // the underlying Firestore query.
  late Stream<List<ServiceListing>> _listingsStream;

  @override
  void initState() {
    super.initState();
    _listingsStream = _firestore.getServiceListings();
    LocationService.selected.addListener(_onLocationChanged);
  }

  void _onLocationChanged() {
    if (mounted) setState(() {});
  }

  void _refreshStream() {
    _listingsStream = _firestore.getServiceListings(
        category: _selectedCategory == 'All' ? null : _selectedCategory);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    LocationService.selected.removeListener(_onLocationChanged);
    super.dispose();
  }

  List<String> get _targetLocations {
    switch (_distanceFilter) {
      case 'Same Area':
        return [_selectedLocation];
      case 'Nearby':
        return _nearbyMap[_selectedLocation] ?? [_selectedLocation];
      default:
        return []; // All — no filter
    }
  }

  /// Reduces a location string to a normalized, comparable form:
  /// lowercase, trimmed, with all punctuation/extra whitespace collapsed
  /// to single spaces. This way "Sangli - Madhavnagar", "sangli- madhavnagar",
  /// "Sangli,Madhavnagar" etc. all normalize to the same thing, so minor
  /// formatting differences between how a provider typed their location
  /// and how a customer picked it from the list don't break matching.
  String _normalizeLoc(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  bool _locationMatches(ServiceListing l, String target) {
    final loc = _normalizeLoc(l.providerLocation);
    final t = _normalizeLoc(target);
    if (loc.isEmpty || t.isEmpty) return false;
    // Exact match (after normalization)
    if (loc == t) return true;
    // One contains the other in full
    if (loc.contains(t) || t.contains(loc)) return true;
    // Match on the area name alone, ignoring a leading "sangli" token —
    // e.g. target "sangli madhavnagar" → area "madhavnagar"
    final tWords = t.split(' ').where((w) => w != 'sangli').toList();
    final areaPart = tWords.join(' ').trim();
    if (areaPart.isNotEmpty && loc.contains(areaPart)) return true;
    // Token-overlap fallback: if every significant word (3+ letters,
    // excluding "sangli") in the target also appears somewhere in the
    // provider's location string, treat it as a match. This catches
    // cases like extra suffixes ("Madhavnagar Branch"), reordered words,
    // or punctuation differences that the exact/substring checks above
    // can miss.
    final locWords = loc.split(' ').where((w) => w.length >= 3 && w != 'sangli').toSet();
    final tSigWords = t.split(' ').where((w) => w.length >= 3 && w != 'sangli').toList();
    if (tSigWords.isNotEmpty &&
        tSigWords.every((w) => locWords.any((lw) => lw.contains(w) || w.contains(lw)))) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nearby Services',
                                style: AppTheme.heroTitleStyle()),
                            GestureDetector(
                              onTap: _pickLocation,
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_rounded,
                                      color: Colors.white70, size: 14),
                                  const SizedBox(width: 4),
                                  Text(_selectedLocation,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12)),
                                  const Icon(Icons.expand_more_rounded,
                                      color: Colors.white70, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _showDistanceSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.tune_rounded,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(_distanceFilter,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Search bar
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search services, providers...',
                        hintStyle: const TextStyle(
                            color: AppTheme.textLight, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppTheme.primary, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: AppTheme.textLight, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Category chips
          StreamBuilder<List<ServiceCategory>>(
            stream: _firestore.getCategories(),
            builder: (context, catSnap) {
              final categories = ['All', ...(catSnap.data ?? []).map((c) => c.name)];
              return Container(
            color: AppTheme.primary,
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SizedBox(
                height: 52,
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (_, i) {
                    final cat = categories[i];
                    final sel = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedCategory = cat;
                        _refreshStream();
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: sel ? AppTheme.accentGradient : null,
                          color: sel ? null : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sel
                                  ? Colors.transparent
                                  : AppTheme.divider),
                        ),
                        child: Text(cat,
                            style: TextStyle(
                                color: sel
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.w500)),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
            },
          ),
          // Listings
          Expanded(
            child: StreamBuilder<List<ServiceListing>>(
              stream: _listingsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: const TextStyle(color: AppTheme.error)));
                }
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primary));
                }

                var listings = snapshot.data!;

                // Location filter
                final targets = _targetLocations;
                if (targets.isNotEmpty) {
                  listings = listings
                      .where((l) =>
                          targets.any((t) => _locationMatches(l, t)))
                      .toList();
                }

                // Search filter
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  listings = listings
                      .where((l) =>
                          l.title.toLowerCase().contains(q) ||
                          l.description.toLowerCase().contains(q) ||
                          l.providerName.toLowerCase().contains(q) ||
                          l.category.toLowerCase().contains(q))
                      .toList();
                }

                if (listings.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📍',
                              style: TextStyle(fontSize: 56)),
                          const SizedBox(height: 16),
                          Text(
                            _distanceFilter == 'All'
                                ? 'No services found'
                                : 'No services in $_selectedLocation',
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Try changing the distance filter to "All"',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () =>
                                setState(() => _distanceFilter = 'All'),
                            icon: const Icon(Icons.expand_outlined, size: 18),
                            label: const Text('Show All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Count banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      color: AppTheme.surface,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${listings.length} service${listings.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _distanceFilter == 'Same Area'
                                ? 'in $_selectedLocation'
                                : _distanceFilter == 'Nearby'
                                    ? 'nearby'
                                    : 'everywhere',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: listings.length,
                        itemBuilder: (_, i) => _NearbyCard(
                          listing: listings[i],
                          userLocation: _selectedLocation,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ServiceListingDetailScreen(
                                  listing: listings[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDistanceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Distance Filter',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...['Same Area', 'Nearby', 'All'].map((opt) {
              final desc = {
                'Same Area': 'Only services in my selected area',
                'Nearby': 'Services in nearby localities',
                'All': 'All services in Sangli',
              };
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _distanceFilter == opt
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: AppTheme.primary,
                ),
                title: Text(opt,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(desc[opt] ?? ''),
                onTap: () {
                  setState(() => _distanceFilter = opt);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _pickLocation() async {
    String filter = '';
    final searchCtrl = TextEditingController();

    // Kick off a fresh fetch in the background, same as home_screen.
    LocationService.warmCache();

    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) {
        final filtered = LocationService.cached
            .where((l) =>
                l.toLowerCase().contains(filter.toLowerCase()))
            .toList();

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, sc) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      const Text('Select Location',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      const Spacer(),
                      IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: (v) => setModal(() => filter = v),
                    decoration: InputDecoration(
                      hintText: 'Search area...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppTheme.primary),
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                // Manual entry option
                if (searchCtrl.text.trim().isNotEmpty &&
                    !LocationService.cached.any((l) =>
                        l.toLowerCase() ==
                        searchCtrl.text.trim().toLowerCase()))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: InkWell(
                      onTap: () =>
                          Navigator.pop(ctx, searchCtrl.text.trim()),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.primary
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add_location_alt_rounded,
                                color: AppTheme.primary, size: 20),
                            const SizedBox(width: 12),
                            Text(
                                'Use "${searchCtrl.text.trim()}"',
                                style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: sc,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final loc = filtered[i];
                      final isSel = loc == _selectedLocation;
                      return ListTile(
                        leading: Icon(Icons.location_on_rounded,
                            color: isSel
                                ? AppTheme.primary
                                : AppTheme.textLight,
                            size: 20),
                        title: Text(loc,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSel
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSel
                                    ? AppTheme.primary
                                    : AppTheme.textPrimary)),
                        trailing: isSel
                            ? const Icon(Icons.check_circle_rounded,
                                color: AppTheme.primary, size: 18)
                            : null,
                        onTap: () => Navigator.pop(ctx, loc),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );

    if (picked != null && picked != _selectedLocation) {
      LocationService.set(picked);
    }
  }
}

// ── Nearby Card ───────────────────────────────────────────────────────────────
class _NearbyCard extends StatelessWidget {
  final ServiceListing listing;
  final String userLocation;
  final VoidCallback onTap;

  const _NearbyCard(
      {required this.listing,
      required this.userLocation,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final catIcon = categoryIconFor(listing.category);
    final catColor = AppTheme.primary;

    final userArea = userLocation
        .toLowerCase()
        .replaceAll('sangli - ', '')
        .trim();
    final isSameArea = listing.providerLocation
        .toLowerCase()
        .contains(userArea);
    final distLabel = isSameArea ? '📍 Same area' : '🗺️ Nearby';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                  child: Icon(catIcon, size: 33, color: catColor)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(listing.category,
                            style: TextStyle(
                                color: catColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Text(distLabel,
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textLight)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 11, color: AppTheme.textLight),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(listing.providerName,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textLight),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  if (listing.providerLocation.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 11, color: AppTheme.textLight),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(listing.providerLocation,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textLight),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${listing.price.toInt()}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary)),
                Text(listing.priceUnit,
                    style: const TextStyle(
                        fontSize: 9, color: AppTheme.textLight)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Book',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}