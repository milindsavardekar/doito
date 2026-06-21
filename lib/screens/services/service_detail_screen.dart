import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../bookings/booking_screen.dart';

class ServiceDetailScreen extends StatefulWidget {
  final ServiceProvider provider;
  const ServiceDetailScreen({super.key, required this.provider});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isFav = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.primary,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () => setState(() => _isFav = !_isFav),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      _isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: _isFav ? AppTheme.error : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient)),
                  Positioned(
                    top: -40, right: -40,
                    child: Container(
                      width: 200, height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24, left: 20, right: 20,
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 16)
                            ],
                          ),
                          child: p.imageUrl.isNotEmpty
                              ? CircleAvatar(
                                  radius: 40,
                                  backgroundImage: NetworkImage(p.imageUrl),
                                  backgroundColor: AppTheme.divider,
                                )
                              : CircleAvatar(
                                  radius: 40,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.2),
                                  child: Text(
                                    p.name.isNotEmpty
                                        ? p.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(p.name,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800)),
                                  if (p.isVerified) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.verified_rounded,
                                        color: Color(0xFF4DD9EC), size: 18),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(p.category,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  RatingStars(rating: p.rating, size: 16),
                                  const SizedBox(width: 6),
                                  Text('(${p.reviewCount} reviews)',
                                      style: const TextStyle(
                                          color: Colors.white60, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats
          SliverToBoxAdapter(
            child: Container(
              color: AppTheme.primary,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Row(
                    children: [
                      _StatChip(
                        label: 'Jobs Done',
                        value: '${p.completedJobs}+',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppTheme.success,
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        label: 'Rate/Hour',
                        value: '₹${p.pricePerHour.toInt()}',
                        icon: Icons.currency_rupee_rounded,
                        color: AppTheme.accent,
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        label: 'Status',
                        value: p.isAvailable ? 'Available' : 'Busy',
                        icon: Icons.circle,
                        color: p.isAvailable ? AppTheme.success : AppTheme.error,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tabs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05), blurRadius: 12)
                  ],
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: AppTheme.textLight,
                  indicatorColor: AppTheme.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                  tabs: const [
                    Tab(text: 'About'),
                    Tab(text: 'Services'),
                    Tab(text: 'Reviews'),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 320,
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildAboutTab(p),
                  _buildServicesTab(p),
                  _buildReviewsTab(p),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: const Icon(Icons.call_outlined,
                    color: AppTheme.primary, size: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: GradientButton(
                label: 'Book Now  ₹${p.pricePerHour.toInt()}/hr',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BookingScreen(provider: p)),
                ),
                icon: Icons.calendar_month_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTab(ServiceProvider p) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(
            '${p.name} is a professional ${p.category.toLowerCase()} expert with extensive experience in providing top-quality home services. Known for punctuality, reliability, and excellent customer satisfaction.',
            style: const TextStyle(
                fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text(p.location,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary)),
            ],
          ),
          if (p.specializations.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Specializations',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: p.specializations
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(s,
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServicesTab(ServiceProvider p) {
    final services = [
      {'name': 'Basic ${p.category}', 'price': '₹${(p.pricePerHour * 1).toInt()}', 'duration': '1 hr'},
      {'name': 'Standard ${p.category}', 'price': '₹${(p.pricePerHour * 2).toInt()}', 'duration': '2 hrs'},
      {'name': 'Premium ${p.category}', 'price': '₹${(p.pricePerHour * 3).toInt()}', 'duration': '3+ hrs'},
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: services.length,
      itemBuilder: (_, i) {
        final s = services[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['name']!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(s['duration']!,
                        style: const TextStyle(
                            color: AppTheme.textLight, fontSize: 12)),
                  ],
                ),
              ),
              Text(s['price']!,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab(ServiceProvider p) {
    final reviews = [
      {'name': 'Sneha P.', 'date': '2 days ago', 'rating': 5, 'text': 'Excellent service! Very professional and on time.'},
      {'name': 'Mohit K.', 'date': '1 week ago', 'rating': 5, 'text': 'Great work. Will definitely book again.'},
      {'name': 'Anita R.', 'date': '2 weeks ago', 'rating': 4, 'text': 'Good service, arrived a bit late but work was perfect.'},
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: reviews.length,
      itemBuilder: (_, i) {
        final r = reviews[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                    child: Text((r['name'] as String)[0],
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['name'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(r['date'] as String,
                            style: const TextStyle(
                                color: AppTheme.textLight, fontSize: 11)),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(
                      r['rating'] as int,
                      (_) => const Icon(Icons.star_rounded,
                          color: AppTheme.accent, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(r['text'] as String,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.4)),
            ],
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _StatChip(
      {required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 14, fontWeight: FontWeight.w800)),
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
