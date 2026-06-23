import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/models.dart';
import '../../services/firebase_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'add_edit_listing_screen.dart';

class ManageListingsScreen extends StatelessWidget {
  const ManageListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final firestoreService = FirestoreService();

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text('My Services'),
        titleTextStyle: AppTheme.appBarTitleStyle(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddEditListingScreen(),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 4),
                    Text('Add',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: AppTheme.primary,
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: StreamBuilder<List<ServiceListing>>(
            stream: firestoreService.getMyListings(uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.error, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Error: \${snapshot.error}',
                          style: const TextStyle(color: AppTheme.error, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primary));
              }

              final listings = snapshot.data!;

              if (listings.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            gradient: AppTheme.accentGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8))
                            ],
                          ),
                          child: const Icon(
                              Icons.home_repair_service_outlined,
                              color: Colors.white,
                              size: 42),
                        ),
                        const SizedBox(height: 24),
                        const Text('No Services Listed',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary)),
                        const SizedBox(height: 10),
                        const Text(
                          'Add your first service to start getting bookings from customers',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                              height: 1.5),
                        ),
                        const SizedBox(height: 28),
                        GradientButton(
                          label: 'Add Your First Service',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AddEditListingScreen(),
                            ),
                          ),
                          icon: Icons.add_circle_outline_rounded,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  // Summary header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Row(
                      children: [
                        _SummaryChip(
                          label: 'Total',
                          value: '${listings.length}',
                          icon: Icons.list_alt_rounded,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 10),
                        _SummaryChip(
                          label: 'Active',
                          value:
                              '${listings.where((l) => l.isActive).length}',
                          icon: Icons.check_circle_outline_rounded,
                          color: AppTheme.success,
                        ),
                        const SizedBox(width: 10),
                        _SummaryChip(
                          label: 'Paused',
                          value:
                              '${listings.where((l) => !l.isActive).length}',
                          icon: Icons.pause_circle_outline_rounded,
                          color: AppTheme.warning,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: listings.length,
                      itemBuilder: (_, i) => _ManageListingCard(
                        listing: listings[i],
                        onEdit: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditListingScreen(
                                listing: listings[i]),
                          ),
                        ),
                        onToggle: () => firestoreService.toggleListingActive(
                            listings[i].id, !listings[i].isActive),
                        onDelete: () =>
                            _confirmDelete(context, listings[i]),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_manage_listings',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const AddEditListingScreen()),
        ),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Service',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ServiceListing listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Service?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            'Are you sure you want to delete "${listing.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirestoreService().deleteServiceListing(listing.id);
    }
  }
}

// ── Manage Card ────────────────────────────────────────────────────────────────
class _ManageListingCard extends StatelessWidget {
  final ServiceListing listing;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ManageListingCard({
    required this.listing,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final catIcon = categoryIconFor(listing.category);
    final catColor = AppTheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: listing.isActive
              ? AppTheme.divider
              : AppTheme.divider.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Opacity(
        opacity: listing.isActive ? 1.0 : 0.65,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 58, height: 58,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                        child: Icon(catIcon, size: 32, color: catColor)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(listing.title,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(listing.description,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  // Active toggle
                  Switch(
                    value: listing.isActive,
                    onChanged: (_) => onToggle(),
                    activeThumbColor: AppTheme.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: AppTheme.divider, height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Category tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
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
                  const SizedBox(width: 8),
                  // Duration
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 11, color: AppTheme.textLight),
                        const SizedBox(width: 4),
                        Text(_formatDuration(listing.durationMinutes),
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Price
                  Text('₹${listing.price.toInt()}',
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary)),
                  const SizedBox(width: 4),
                  Text(listing.priceUnit,
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textLight)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: listing.isActive
                          ? AppTheme.success.withValues(alpha: 0.1)
                          : AppTheme.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            color: listing.isActive
                                ? AppTheme.success
                                : AppTheme.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          listing.isActive ? 'Active' : 'Paused',
                          style: TextStyle(
                              color: listing.isActive
                                  ? AppTheme.success
                                  : AppTheme.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Edit
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Edit',
                        style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.error, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.error.withValues(alpha: 0.08),
                      minimumSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
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

class _SummaryChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SummaryChip(
      {required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}