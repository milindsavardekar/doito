import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firebase_services.dart';
import '../../theme/app_theme.dart';
//import '../../widgets/common_widgets.dart';
import '../services/service_listing_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _selectedCategory = 'All';
  String _sortBy = 'Newest';
  final _searchCtrl = TextEditingController();
  final _firestore = FirestoreService();

  final _categories = ['All', ...MockData.categories.map((c) => c.name)];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          _buildHeader(),
          _buildCategoryChips(),
          Expanded(child: _buildGrid()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Explore',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800)),
                      Text('Find services near you',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showSortSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sort_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(_sortBy,
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
            // Search
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
                onChanged: (_) => setState(() {}),
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
                            setState(() {});
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
    );
  }

  Widget _buildCategoryChips() {
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
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final sel = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
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
                    boxShadow: sel
                        ? [
                            BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8)
                          ]
                        : [],
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
  }

  Widget _buildGrid() {
    return StreamBuilder<List<ServiceListing>>(
      stream: _firestore.getServiceListings(
          category:
              _selectedCategory == 'All' ? null : _selectedCategory),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppTheme.error, size: 40),
                  const SizedBox(height: 12),
                  Text(snapshot.error.toString(),
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary));
        }

        var listings = snapshot.data!;

        // search filter
        if (_searchCtrl.text.isNotEmpty) {
          final q = _searchCtrl.text.toLowerCase();
          listings = listings
              .where((l) =>
                  l.title.toLowerCase().contains(q) ||
                  l.description.toLowerCase().contains(q) ||
                  l.providerName.toLowerCase().contains(q) ||
                  l.category.toLowerCase().contains(q))
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
        }

        if (listings.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔍', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                Text(
                  _searchCtrl.text.isNotEmpty
                      ? 'No results for "${_searchCtrl.text}"'
                      : _selectedCategory != 'All'
                          ? 'No services in "$_selectedCategory" yet'
                          : 'No services listed yet',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text('Check back soon!',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: listings.length,
          itemBuilder: (_, i) => _ExploreCard(
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

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sort By',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...[
              'Newest',
              'Top Rated',
              'Price: Low to High',
              'Price: High to Low'
            ].map((s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _sortBy == s
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: AppTheme.primary,
                  ),
                  title: Text(s,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500)),
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

// ── Explore Grid Card ──────────────────────────────────────────────────────────
class _ExploreCard extends StatelessWidget {
  final ServiceListing listing;
  final VoidCallback onTap;
  const _ExploreCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final catData =
        MockData.categories.where((c) => c.name == listing.category).toList();
    final catIcon = catData.isNotEmpty ? catData.first.iconData : Icons.build_rounded;
    final catColor = AppTheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon area
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                height: 90,
                width: double.infinity,
                color: catColor.withValues(alpha: 0.1),
                child: Center(
                  child: Icon(catIcon, size: 46, color: catColor),
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(listing.category,
                      style: TextStyle(
                          fontSize: 10,
                          color: catColor,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(listing.providerName,
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('₹${listing.price.toInt()}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary)),
                          Text(listing.priceUnit,
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.textLight)),
                        ],
                      ),
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                            color: AppTheme.success,
                            shape: BoxShape.circle),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
