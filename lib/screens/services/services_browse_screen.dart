import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firebase_services.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../provider/provider_public_profile_screen.dart';
import 'service_listing_detail_screen.dart';

class ServicesBrowseScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialLocation;
  const ServicesBrowseScreen({super.key, this.initialCategory, this.initialLocation});

  @override
  State<ServicesBrowseScreen> createState() => _ServicesBrowseScreenState();
}

class _ServicesBrowseScreenState extends State<ServicesBrowseScreen> {
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
    LocationService.selected.addListener(_onLocationChanged);
  }

  void _onLocationChanged() {
    if (mounted) setState(() {});
  }

  String _sortBy           = 'Newest';
  String _searchQuery      = '';
  final _searchCtrl        = TextEditingController();
  final _firestore         = FirestoreService();

  @override
  void dispose() {
    _searchCtrl.dispose();
    LocationService.selected.removeListener(_onLocationChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          _buildHeader(),
          _buildCategoryBar(),
          Expanded(child: _buildListings()),
        ],
      ),
    );
  }

  // ── Header with search ──────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              top: -30, right: -30,
              child: Container(
                width: 150, height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Services',
                              style: AppTheme.heroTitleStyle()),
                          const Text('Find the right service for you',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _pickLocation,
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(children: [
                            const Icon(Icons.location_on_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 90),
                              child: Text(
                                LocationService.selected.value
                                    .replaceFirst('Sangli - ', ''),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ]),
                        ),
                      ),
                      GestureDetector(
                        onTap: _showSortSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(children: [
                            const Icon(Icons.sort_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(_sortBy,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ]),
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
                      hintText: 'Search by service, category, location...',
                      hintStyle: const TextStyle(
                          color: AppTheme.textLight, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppTheme.primary, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
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
          ],
        ),
      ),
    );
  }

  // ── Category chips ──────────────────────────────────────────────────────────
  Widget _buildCategoryBar() {
    return StreamBuilder<List<ServiceCategory>>(
      stream: _firestore.getCategories(),
      builder: (context, snapshot) {
        final categories = ['All', ...(snapshot.data ?? []).map((c) => c.name)];
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  final sel = _selectedCategory == cat;
                  final icon = cat != 'All' ? categoryIconFor(cat) : null;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: sel ? AppTheme.accentGradient : null,
                        color: sel ? null : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel ? Colors.transparent : AppTheme.divider),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                    color: AppTheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 8)
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon,
                                size: 17,
                                color: sel ? Colors.white : AppTheme.primary),
                            const SizedBox(width: 5),
                          ],
                          Text(cat,
                              style: TextStyle(
                                  color: sel
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: sel
                                      ? FontWeight.w700
                                      : FontWeight.w500)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Listings from Firestore ─────────────────────────────────────────────────
  Widget _buildListings() {
    return StreamBuilder<List<ServiceListing>>(
      stream: _firestore.getServiceListings(
          category:
              _selectedCategory == 'All' ? null : _selectedCategory),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load services'));
        }
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary));
        }

        var listings = snapshot.data!;

        // search filter — title, description, category, provider name, location
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          listings = listings
              .where((l) =>
                  l.title.toLowerCase().contains(q) ||
                  l.description.toLowerCase().contains(q) ||
                  l.category.toLowerCase().contains(q) ||
                  l.providerName.toLowerCase().contains(q) ||
                  l.providerLocation.toLowerCase().contains(q))
              .toList();
        }

        // sort
        switch (_sortBy) {
          case 'Price: Low to High':
            listings.sort((a, b) => a.price.compareTo(b.price));
          case 'Price: High to Low':
            listings.sort((a, b) => b.price.compareTo(a.price));
          case 'Top Rated':
            listings.sort((a, b) => b.rating.compareTo(a.rating));
          default: // Newest
            break;
        }

        if (listings.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔍', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No results for "$_searchQuery"'
                        : 'No services in this category yet',
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check back soon or try a different search',
                    style: TextStyle(
                        color: AppTheme.textLight, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: listings.length,
          itemBuilder: (_, i) => _ServiceCard(
            listing: listings[i],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ServiceListingDetailScreen(listing: listings[i]),
              ),
            ),
          ),
        );
      },
    );
  }

  void _pickLocation() async {
    String filter = '';
    final searchCtrl = TextEditingController();

    LocationService.warmCache();

    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) {
        final filtered = LocationService.cached
            .where((l) => l.toLowerCase().contains(filter.toLowerCase()))
            .toList();

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, sc) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40, height: 4,
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
                              fontSize: 16, fontWeight: FontWeight.w700)),
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
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: sc,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final loc = filtered[i];
                      final isSel = loc == LocationService.selected.value;
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

    if (picked != null) {
      LocationService.set(picked);
    }
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 4, height: 22,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              const Text('Sort Services',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 16),
            ...[
              'Newest',
              'Top Rated',
              'Price: Low to High',
              'Price: High to Low',
            ].map((s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      gradient:
                          _sortBy == s ? AppTheme.accentGradient : null,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _sortBy == s
                              ? AppTheme.primary
                              : AppTheme.divider,
                          width: 2),
                    ),
                    child: _sortBy == s
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 12)
                        : null,
                  ),
                  title: Text(s,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    setState(() => _sortBy = s);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}

// ── Service Card ───────────────────────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final ServiceListing listing;
  final VoidCallback onTap;

  const _ServiceCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final catIcon  = categoryIconFor(listing.category);
    final catColor = AppTheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            // ── Main content row ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category icon
                  Column(
                    children: [
                      Container(
                        width: 68, height: 68,
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                            child: Icon(catIcon,
                                size: 36, color: catColor)),
                      ),
                      const SizedBox(height: 4),
                      if (listing.reviewCount > 0)
                        RatingStars(rating: listing.rating, size: 12)
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                color: AppTheme.textLight.withValues(alpha: 0.5),
                                size: 12),
                            const SizedBox(width: 3),
                            Text('New',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textLight)),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + category badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(listing.title,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(listing.category,
                                  style: TextStyle(
                                      color: catColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),

                        // Description preview
                        Text(
                          listing.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              height: 1.4),
                        ),
                        const SizedBox(height: 10),

                        // Provider info row
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProviderPublicProfileScreen(
                                providerId: listing.providerId,
                                providerName: listing.providerName,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Provider avatar initial
                              Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.accentGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    listing.providerName.isNotEmpty
                                        ? listing.providerName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(listing.providerName,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),

                        // Location (if available)
                        if (listing.providerLocation.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Row(children: [
                            const Icon(Icons.location_on_outlined,
                                size: 13, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(listing.providerLocation,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ]),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Footer bar ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20)),
                border: Border(
                  top: BorderSide(color: AppTheme.divider.withValues(alpha: 0.7)),
                ),
              ),
              child: Row(
                children: [
                  // Duration
                  const Icon(Icons.access_time_rounded,
                      size: 14, color: AppTheme.textLight),
                  const SizedBox(width: 4),
                  Text(_formatDuration(listing.durationMinutes),
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),

                  // Rating (if any)
                  if (listing.reviewCount > 0) ...[
                    const SizedBox(width: 14),
                    const Icon(Icons.star_rounded,
                        size: 14, color: AppTheme.accent),
                    const SizedBox(width: 3),
                    Text(listing.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    Text(' (${listing.reviewCount})',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textLight)),
                  ],

                  const Spacer(),

                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${listing.price.toInt()}',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary),
                      ),
                      Text(listing.priceUnit,
                          style: const TextStyle(
                              fontSize: 10, color: AppTheme.textLight)),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Book button
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3)),
                        ],
                      ),
                      child: const Text('Book Now',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}hr' : '${h}hr ${m}min';
  }
}
