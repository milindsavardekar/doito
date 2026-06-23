import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/models.dart';
import '../../services/firebase_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';
import '../services/manage_listings_screen.dart';
import '../services/add_edit_listing_screen.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  AppUser? _user;
  final _firestore = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final user = await AuthService().getUserData(uid);
    if (!mounted) return;
    if (user?.isBlocked == true) {
      await AuthService().signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }
    setState(() => _user = user);
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning ☀️';
    if (h < 17) return 'Good Afternoon 👋';
    return 'Good Evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.primaryDeep,
            automaticallyImplyLeading: false,
            expandedHeight: 64,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                      decoration:
                          const BoxDecoration(gradient: AppTheme.deepGradient)),
                  // Subtle decorative glow — signature touch, used once
                  Positioned(
                    top: -40, right: -30,
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accent.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(
                        (_user?.name.isNotEmpty ?? false)
                            ? _user!.name[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_greeting(),
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11,
                              fontWeight: FontWeight.w500, letterSpacing: 0.2)),
                      Text(_user?.name.split(' ').first ?? 'Provider',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 17, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.storefront_rounded,
                            color: AppTheme.accentLight, size: 14),
                        SizedBox(width: 5),
                        Text('Provider',
                            style: TextStyle(color: Colors.white,
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats from Firestore — earnings-led summary strip
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(gradient: AppTheme.deepGradient),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: StreamBuilder<List<ServiceListing>>(
                stream: _firestore.getMyListings(uid),
                builder: (ctx, listingSnap) {
                  final listings = listingSnap.data ?? [];
                  final activeCount =
                      listings.where((l) => l.isActive).length;
                    return StreamBuilder<List<Booking>>(
                      stream: _firestore.getProviderBookings(uid),
                      builder: (ctx2, bookingSnap) {
                        final bookings = bookingSnap.data ?? [];
                        final completed = bookings
                            .where((b) => b.status == 'completed')
                            .toList();
                        final earnings = completed
                            .fold<double>(0, (sum, b) => sum + b.amount);

                        return Container(
                          padding:
                              const EdgeInsets.fromLTRB(20, 20, 20, 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryDeep
                                    .withValues(alpha: 0.18),
                                blurRadius: 28,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Signature element: total earnings
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${earnings.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                        letterSpacing: -0.5),
                                  ),
                                  const SizedBox(width: 8),
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      'total earnings',
                                      style: TextStyle(
                                          fontSize: 12.5,
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(
                                  color: AppTheme.divider, height: 1),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  _StatItem(
                                    label: 'Listed',
                                    value: '${listings.length}',
                                    icon: Icons.list_alt_rounded,
                                  ),
                                  _vDivider(),
                                  _StatItem(
                                    label: 'Active',
                                    value: '$activeCount',
                                    icon: Icons.check_circle_rounded,
                                    valueColor: AppTheme.success,
                                  ),
                                  _vDivider(),
                                  _StatItem(
                                    label: 'Bookings',
                                    value: '${bookings.length}',
                                    icon: Icons.calendar_today_rounded,
                                  ),
                                  _vDivider(),
                                  _StatItem(
                                    label: 'Done',
                                    value: '${completed.length}',
                                    icon: Icons.task_alt_rounded,
                                    valueColor: AppTheme.accent,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Actions',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.add_circle_outline_rounded,
                          label: 'Add Service',
                          gradient: AppTheme.accentGradient,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const AddEditListingScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.list_alt_rounded,
                          label: 'My Services',
                          gradient: AppTheme.deepGradient,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const ManageListingsScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Recent Services
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Your Listed Services',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ManageListingsScreen()),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Manage',
                            style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded,
                            color: AppTheme.primary, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          StreamBuilder<List<ServiceListing>>(
            stream: _firestore.getMyListings(uid),
            builder: (ctx, snap) {
              if (snap.hasError) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Error loading services:\n${snap.error}',
                        style: const TextStyle(color: AppTheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }
              if (!snap.hasData) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                          color: AppTheme.primary),
                    ),
                  ),
                );
              }
              final listings = snap.data!;
              if (listings.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Container(
                          width: 88, height: 88,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.storefront_outlined,
                              size: 40, color: AppTheme.primary),
                        ),
                        const SizedBox(height: 18),
                        const Text('No services yet',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary)),
                        const SizedBox(height: 8),
                        const Text(
                            'Add your first service to start receiving bookings',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                                height: 1.5)),
                        const SizedBox(height: 20),
                        GradientButton(
                          label: 'Add First Service',
                          onTap: () => Navigator.push(
                            ctx,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const AddEditListingScreen()),
                          ),
                          icon: Icons.add_rounded,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _ProviderServiceTile(listing: listings[i]),
                  childCount: listings.take(5).length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_provider_home',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditListingScreen()),
        ),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Service',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? valueColor;

  const _StatItem({
    required this.label, required this.value,
    required this.icon, this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.textLight, size: 17),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textLight, fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

Widget _vDivider() => Container(
      width: 1,
      height: 38,
      color: AppTheme.divider,
    );

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon, required this.label,
    required this.gradient, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700),
                  maxLines: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderServiceTile extends StatelessWidget {
  final ServiceListing listing;
  const _ProviderServiceTile({required this.listing});

  @override
  Widget build(BuildContext context) {
    final catIcon = categoryIconFor(listing.category);
    final catColor = AppTheme.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
                child: Icon(catIcon, size: 28, color: catColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listing.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(listing.category,
                    style: TextStyle(
                        fontSize: 12, color: catColor,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${listing.price.toInt()}',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: listing.isActive
                      ? AppTheme.success
                      : AppTheme.warning,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}