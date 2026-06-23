import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/models.dart';
import '../../services/firebase_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../services/service_listing_detail_screen.dart';

class ProviderPublicProfileScreen extends StatefulWidget {
  final String providerId;
  final String providerName;

  const ProviderPublicProfileScreen({
    super.key,
    required this.providerId,
    required this.providerName,
  });

  @override
  State<ProviderPublicProfileScreen> createState() =>
      _ProviderPublicProfileScreenState();
}

class _ProviderPublicProfileScreenState
    extends State<ProviderPublicProfileScreen> {
  final _auth = AuthService();
  final _firestore = FirestoreService();

  AppUser? _provider;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final user = await _auth.getUserData(widget.providerId);
    if (mounted) setState(() { _provider = user; _loading = false; });
  }

  Future<void> _openWhatsApp(String phone) async {
    if (phone.isEmpty) return;
    final digits = normalizeMobile(phone);
    final uri = Uri.parse('https://wa.me/91$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(child: _buildInfo()),
                _buildListings(),
                _buildReviews(),
              ],
            ),
    );
  }

  Widget _buildAppBar() {
    final name = _provider?.name ?? widget.providerName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppTheme.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  child: Text(initial,
                      style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
                const SizedBox(height: 12),
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                if (_provider?.phone.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _openWhatsApp(_provider!.phone),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const FaIcon(FontAwesomeIcons.whatsapp,
                                color: Colors.white, size: 13),
                          ),
                        ),
                        Text(_provider!.phone,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                if (_provider != null && _provider!.rating > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppTheme.accentLight, size: 16),
                        const SizedBox(width: 4),
                        Text(_provider!.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        Text(' (${_provider!.reviewCount} reviews)',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfo() {
    if (_provider == null) return const SizedBox.shrink();
    final p = _provider!;
    final hasContactInfo = p.addresses.isNotEmpty ||
        p.email.isNotEmpty ||
        p.phone.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Provider Info',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.verified_outlined,
            text: 'Service Provider',
            color: AppTheme.primary,
          ),
          if (p.addresses.isNotEmpty)
            _InfoRow(
              icon: Icons.location_on_outlined,
              text: p.addresses.first,
            ),
          if (p.phone.isNotEmpty)
            _InfoRow(
              icon: Icons.call_outlined,
              text: p.phone,
              onTap: () => launchUrl(Uri(scheme: 'tel', path: p.phone)),
            ),
          if (p.email.isNotEmpty)
            _InfoRow(
              icon: Icons.email_outlined,
              text: p.email,
              onTap: () => launchUrl(Uri(scheme: 'mailto', path: p.email)),
            ),
          if (!hasContactInfo)
            const Text(
              'This provider hasn\'t added contact details yet.',
              style: TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textLight,
                  fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }

  Widget _buildListings() {
    return StreamBuilder<List<ServiceListing>>(
      stream: _firestore.getMyListings(widget.providerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            ),
          );
        }

        final listings = snapshot.data!
            .where((l) => l.isActive)
            .toList();

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  const Text('Services',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${listings.length}',
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (listings.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No active services',
                        style: TextStyle(color: AppTheme.textLight)),
                  ),
                )
              else
                ...listings.map((l) => _ListingCard(
                      listing: l,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ServiceListingDetailScreen(listing: l),
                        ),
                      ),
                    )),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildReviews() {
    return StreamBuilder<List<Review>>(
      stream: _firestore.getProviderReviews(widget.providerId),
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? [];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        if (reviews.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  const Text('Reviews',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${reviews.length}',
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...reviews.map((r) => _ReviewCard(review: r)),
            ]),
          ),
        );
      },
    );
  }
}

// ── Review Card ───────────────────────────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: const BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    review.userName.isNotEmpty
                        ? review.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    if (review.createdAt != null)
                      Text(DateFormat('d MMM yyyy').format(review.createdAt!),
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textLight)),
                  ],
                ),
              ),
              RatingStars(rating: review.rating, size: 13),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.comment,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback? onTap;
  const _InfoRow(
      {required this.icon,
      required this.text,
      this.color = AppTheme.textSecondary,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13,
                      color: onTap != null ? AppTheme.primary : color,
                      fontWeight:
                          onTap != null ? FontWeight.w600 : FontWeight.w400))),
        ],
      ),
    );
    if (onTap == null) return row;
    return GestureDetector(onTap: onTap, child: row);
  }
}

// ── Listing Card ──────────────────────────────────────────────────────────────
class _ListingCard extends StatelessWidget {
  final ServiceListing listing;
  final VoidCallback onTap;
  const _ListingCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final catIcon = categoryIconFor(listing.category);
    final catColor = AppTheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
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
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${listing.price.toInt()}',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary)),
                Text(listing.priceUnit,
                    style: const TextStyle(
                        fontSize: 9, color: AppTheme.textLight)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}