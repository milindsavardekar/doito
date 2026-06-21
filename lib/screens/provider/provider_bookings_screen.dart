import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/models.dart';
import '../../services/firebase_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../bookings/rate_customer_sheet.dart';

class ProviderBookingsScreen extends StatefulWidget {
  const ProviderBookingsScreen({super.key});

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _firestore = FirestoreService();

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
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.primary,
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        title: const Text('Customer Bookings'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppTheme.primary,
            child: TabBar(
              controller: _tabCtrl,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              indicatorColor: const Color(0xFF4DD9EC),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14),
              tabs: const [
                Tab(text: 'New'),
                Tab(text: 'Ongoing'),
                Tab(text: 'Done'),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        color: AppTheme.primary,
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: StreamBuilder<List<Booking>>(
            stream: _firestore.getProviderBookings(uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primary));
              }
              final all = snapshot.data!;
              final newB = all
                  .where((b) =>
                      b.status == 'confirmed' || b.status == 'pending')
                  .toList();
              final ongoing =
                  all.where((b) => b.status == 'in_progress').toList();
              final done = all
                  .where((b) =>
                      b.status == 'completed' || b.status == 'cancelled')
                  .toList();

              return TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildList(newB, '📬', 'No new bookings',
                      'New customer bookings will appear here'),
                  _buildList(ongoing, '⚙️', 'Nothing in progress',
                      'Accepted bookings appear here'),
                  _buildList(done, '✅', 'No completed bookings',
                      'Finished jobs will appear here'),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<Booking> bookings, String emoji, String title,
      String sub) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            Text(sub,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: bookings.length,
      itemBuilder: (_, i) => _ProviderBookingCard(booking: bookings[i]),
    );
  }
}

class _ProviderBookingCard extends StatefulWidget {
  final Booking booking;
  const _ProviderBookingCard({required this.booking});

  @override
  State<_ProviderBookingCard> createState() => _ProviderBookingCardState();
}

class _ProviderBookingCardState extends State<_ProviderBookingCard> {
  ({double rating, int count})? _customerRating;

  @override
  void initState() {
    super.initState();
    _loadCustomerRating();
  }

  void _loadCustomerRating() async {
    final customerId = widget.booking.userId;
    if (customerId == null || customerId.isEmpty) return;
    try {
      final summary =
          await FirestoreService().getCustomerRatingSummary(customerId);
      if (mounted && summary != null) {
        setState(() => _customerRating = summary);
      }
    } catch (_) {
      // Non-critical — booking card still works fine without this badge.
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final firestore = FirestoreService();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(booking.serviceType,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                ),
                StatusBadge(status: booking.status),
              ],
            ),
            if (_customerRating != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 13, color: AppTheme.textLight),
                  const SizedBox(width: 4),
                  Text(
                    (booking.customerName?.trim().isNotEmpty ?? false)
                        ? booking.customerName!.trim()
                        : 'Customer',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.star_rounded,
                      size: 13, color: AppTheme.accent),
                  const SizedBox(width: 2),
                  Text(
                    '${_customerRating!.rating.toStringAsFixed(1)} (${_customerRating!.count})',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            _Row(Icons.calendar_today_outlined,
                DateFormat('EEE, d MMM · h:mm a')
                    .format(booking.scheduledDate)),
            const SizedBox(height: 6),
            _Row(Icons.location_on_outlined, booking.address),
            if (booking.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              _Row(Icons.note_outlined, booking.notes!),
            ],
            const SizedBox(height: 14),
            const Divider(color: AppTheme.divider, height: 1),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₹${booking.amount.toInt()}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary)),
                // Action buttons
                if (booking.status == 'confirmed' ||
                    booking.status == 'pending')
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => firestore
                            .updateBookingStatus(booking.id, 'cancelled'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: AppTheme.error),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                        ),
                        child: const Text('Decline',
                            style: TextStyle(fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => firestore
                            .updateBookingStatus(booking.id, 'in_progress'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                        ),
                        child: const Text('Accept',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                if (booking.status == 'in_progress')
                  ElevatedButton.icon(
                    onPressed: () => firestore
                        .updateBookingStatus(booking.id, 'completed'),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Mark Done'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                  ),
                if (booking.status == 'completed' && !booking.isCustomerRated)
                  OutlinedButton.icon(
                    onPressed: () => showRateCustomerSheet(context, booking),
                    icon: const Icon(Icons.star_outline_rounded, size: 16),
                    label: const Text('Rate Customer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                  )
                else if (booking.status == 'completed' &&
                    booking.isCustomerRated)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 14, color: AppTheme.success),
                        SizedBox(width: 4),
                        Text('Customer Rated',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.success)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Row(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppTheme.textLight),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary,
                  height: 1.4)),
        ),
      ],
    );
  }
}
