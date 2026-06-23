import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/models.dart';
import '../../services/firebase_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../bookings/booking_screen.dart';
import '../provider/provider_public_profile_screen.dart';

class ServiceListingDetailScreen extends StatefulWidget {
  final ServiceListing listing;
  const ServiceListingDetailScreen({super.key, required this.listing});

  @override
  State<ServiceListingDetailScreen> createState() =>
      _ServiceListingDetailScreenState();
}

class _ServiceListingDetailScreenState
    extends State<ServiceListingDetailScreen> {
  ServiceProvider? _provider;
  bool _providerLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProvider();
  }

  void _loadProvider() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.listing.providerId)
          .get();
      if (snap.exists && snap.data() != null && mounted) {
        setState(() {
          _provider = ServiceProvider.fromFirestore(snap.data()!, snap.id);
          _providerLoading = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _providerLoading = false);
  }

  ServiceProvider get effectiveProvider => _provider ??
      ServiceProvider(
        id: widget.listing.providerId,
        name: widget.listing.providerName,
        category: widget.listing.category,
        rating: widget.listing.rating,
        reviewCount: widget.listing.reviewCount,
        imageUrl: '',
        pricePerHour: widget.listing.price,
        isVerified: false,
        isAvailable: true,
        location: widget.listing.providerLocation,
        specializations: [],
        completedJobs: 0,
        phone: widget.listing.providerPhone,
      );

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h hr' : '$h hr $m min';
  }

  Future<void> _callProvider() async {
    final phone = widget.listing.providerPhone.isNotEmpty
        ? widget.listing.providerPhone
        : _provider?.phone ?? '';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contact number available')),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp() async {
    final phone = widget.listing.providerPhone.isNotEmpty
        ? widget.listing.providerPhone
        : _provider?.phone ?? '';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contact number available')),
      );
      return;
    }
    // wa.me needs the number with country code, no '+', no spaces.
    // The app assumes India (+91) for bare 10-digit numbers, matching
    // toE164()'s default elsewhere in the app.
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
    final l = widget.listing;
    final catIcon  = categoryIconFor(l.category);
    final catColor = AppTheme.primary;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          // Main content - Expanded to fill remaining space
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Hero AppBar
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 240,
                  backgroundColor: AppTheme.primary,
                  leading: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                          gradient: AppTheme.primaryGradient),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -40, right: -40,
                            child: Container(
                              width: 220, height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.07),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    width: 80, height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.4),
                                          width: 2),
                                    ),
                                    child: Center(
                                        child: Icon(catIcon,
                                            size: 44, color: Colors.white)),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: catColor.withValues(alpha: 0.35),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(l.category,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(l.title,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800,
                                                height: 1.2)),
                                        const SizedBox(height: 4),
                                        Row(children: [
                                          const Icon(Icons.person_outline_rounded,
                                              color: Colors.white70, size: 13),
                                          const SizedBox(width: 4),
                                          Text(l.providerName,
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 13)),
                                        ]),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Body content
                SliverToBoxAdapter(
                  child: Container(
                    color: AppTheme.primary,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Price + quick info chips
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.accentGradient,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                          color: AppTheme.primary.withValues(alpha: 0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('₹${l.price.toInt()}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 26,
                                              fontWeight: FontWeight.w800,
                                              height: 1)),
                                      const SizedBox(height: 2),
                                      Text(l.priceUnit,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                _InfoChip(
                                    icon: Icons.access_time_rounded,
                                    label: _formatDuration(l.durationMinutes),
                                    color: AppTheme.primary),
                                _InfoChip(
                                    icon: Icons.star_rounded,
                                    label: l.reviewCount > 0
                                        ? '${l.rating.toStringAsFixed(1)} (${l.reviewCount})'
                                        : 'New',
                                    color: AppTheme.accent),
                                if (l.providerLocation.isNotEmpty)
                                  _InfoChip(
                                      icon: Icons.location_on_outlined,
                                      label: l.providerLocation,
                                      color: AppTheme.primary),
                              ],
                            ),

                            const SizedBox(height: 24),
                            const Divider(color: AppTheme.divider),
                            const SizedBox(height: 20),

                            // Description
                            const Text('About this Service',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary)),
                            const SizedBox(height: 10),
                            Text(l.description,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                    height: 1.7)),

                            const SizedBox(height: 24),

                            // What's included
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: AppTheme.primary.withValues(alpha: 0.15)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.accentGradient,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                          Icons.check_circle_outline_rounded,
                                          color: Colors.white,
                                          size: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text("What's included",
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary)),
                                  ]),
                                  const SizedBox(height: 12),
                                  ...(l.whatsIncluded.isNotEmpty
                                          ? l.whatsIncluded
                                          : ServiceListing
                                              .defaultWhatsIncluded(
                                                  l.durationMinutes))
                                      .map((item) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(children: [
                                          const Icon(Icons.check_rounded,
                                              size: 16,
                                              color: AppTheme.accent),
                                          const SizedBox(width: 10),
                                          Expanded(
                                              child: Text(item,
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          AppTheme.textSecondary))),
                                        ]),
                                      )),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Provider card
                            const Text('Service Provider',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary)),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 12)
                                ],
                              ),
                              child: _providerLoading
                                  ? const _ProviderSkeleton()
                                  : Column(
                                      children: [
                                        GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ProviderPublicProfileScreen(
                                                providerId: l.providerId,
                                                providerName: l.providerName,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 52, height: 52,
                                                decoration: BoxDecoration(
                                                  gradient: AppTheme.accentGradient,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    l.providerName.isNotEmpty
                                                        ? l.providerName[0]
                                                            .toUpperCase()
                                                        : '?',
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 22),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(children: [
                                                      Text(l.providerName,
                                                          style: const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight.w700)),
                                                      if (_provider?.isVerified ==
                                                          true) ...[
                                                        const SizedBox(width: 5),
                                                        const Icon(
                                                            Icons.verified_rounded,
                                                            color: AppTheme.primary,
                                                            size: 16),
                                                      ],
                                                    ]),
                                                    const SizedBox(height: 3),
                                                    Text(l.category,
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            color: AppTheme.primary,
                                                            fontWeight:
                                                                FontWeight.w600)),
                                                    if (_provider != null &&
                                                        _provider!.rating > 0) ...[
                                                      const SizedBox(height: 4),
                                                      Row(children: [
                                                        RatingStars(
                                                            rating: _provider!.rating,
                                                            size: 13),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                            '${_provider!.completedJobs} jobs done',
                                                            style: const TextStyle(
                                                                fontSize: 11,
                                                                color:
                                                                    AppTheme.textLight)),
                                                      ]),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              const Icon(
                                                  Icons.chevron_right_rounded,
                                                  color: AppTheme.textLight,
                                                  size: 22),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        const Divider(color: AppTheme.divider),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            if (l.providerLocation.isNotEmpty) ...[
                                              const Icon(Icons.location_on_outlined,
                                                  size: 15, color: AppTheme.primary),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: Text(l.providerLocation,
                                                    style: const TextStyle(
                                                        fontSize: 13,
                                                        color:
                                                            AppTheme.textSecondary)),
                                              ),
                                            ] else
                                              const Spacer(),
                                            GestureDetector(
                                              onTap: _openWhatsApp,
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                    right: 8),
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                          0xFF25D366)
                                                      .withValues(alpha: 0.12),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const FaIcon(
                                                    FontAwesomeIcons.whatsapp,
                                                    color: Color(0xFF25D366),
                                                    size: 18),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: _callProvider,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 16, vertical: 8),
                                                decoration: BoxDecoration(
                                                  gradient: AppTheme.accentGradient,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  boxShadow: [
                                                    BoxShadow(
                                                        color: AppTheme.primary
                                                            .withValues(alpha: 0.3),
                                                        blurRadius: 8,
                                                        offset:
                                                            const Offset(0, 3)),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.call_rounded,
                                                        color: Colors.white,
                                                        size: 15),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      l.providerPhone.isNotEmpty
                                                          ? l.providerPhone
                                                          : 'Call',
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                            ),

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // ✅ FIXED: Bottom Book Button - Properly placed at bottom
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('₹${l.price.toInt()}',
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary)),
                      Text(l.priceUnit,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textLight)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingScreen(listing: widget.listing),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Book Now',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widgets
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ProviderSkeleton extends StatelessWidget {
  const _ProviderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(radius: 24, backgroundColor: AppTheme.divider),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                width: 130,
                height: 14,
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 8),
            Container(
                width: 80,
                height: 12,
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(6))),
          ],
        ),
      ],
    );
  }
}