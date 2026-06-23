import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/models.dart';
import '../../services/firebase_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../provider/provider_public_profile_screen.dart';
import 'rate_booking_sheet.dart';
class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key});

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen>
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

  static const double _tabBarHeight = 48;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final headerHeight = statusBarHeight + kToolbarHeight + _tabBarHeight;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: AppTheme.appBarTitleStyle(color: Colors.white),
        title: const Text('My Bookings'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(_tabBarHeight),
          child: TabBar(
            controller: _tabCtrl,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: const Color(0xFF4DD9EC),
            indicatorWeight: 3,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14),
            tabs: const [
              Tab(text: 'Booked'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // One continuous gradient behind the status bar + title + tab
          // bar, instead of two separate gradient boxes stacked on top of
          // each other (which produced a hard, banded seam where the first
          // gradient's dark end met the second gradient's bright start).
          Container(
            height: headerHeight,
            decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          ),
          Padding(
            padding: EdgeInsets.only(top: headerHeight),
            child: uid == null
                ? const Center(child: Text('Please sign in to view bookings'))
                : Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: StreamBuilder<List<Booking>>(
                      stream: _firestore.getUserBookings(uid),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                              child: Text('Failed to load bookings'));
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primary),
                          );
                        }

                        final all = snapshot.data!;
                        final upcoming = all
                            .where((b) =>
                                b.status == 'confirmed' ||
                                b.status == 'pending' ||
                                b.status == 'in_progress')
                            .toList();
                        final completed =
                            all.where((b) => b.status == 'completed').toList();
                        final cancelled =
                            all.where((b) => b.status == 'cancelled').toList();

                        return TabBarView(
                          controller: _tabCtrl,
                          children: [
                            _buildList(upcoming, 'No booked services',
                                '📅', 'Your booked services will appear here'),
                            _buildList(completed, 'No completed bookings',
                                '✅', 'Completed services will appear here'),
                            _buildList(cancelled, 'No cancelled bookings',
                                '🚫', 'Cancelled bookings will appear here'),
                          ],
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Booking> bookings, String title, String emoji,
      String subtitle) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
      itemCount: bookings.length,
      itemBuilder: (_, i) => _BookingCard(
        booking: bookings[i],
        onCancel: bookings[i].status == 'confirmed' || bookings[i].status == 'pending'
            ? () => _cancelBooking(bookings[i].id)
            : null,
        onRate: bookings[i].status == 'completed' && !bookings[i].isRated
            ? () => showRateBookingSheet(context, bookings[i])
            : null,
        onProviderTap: (bookings[i].providerId?.isNotEmpty == true)
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderPublicProfileScreen(
                      providerId: bookings[i].providerId ?? '',
                      providerName: bookings[i].providerName,
                    ),
                  ),
                )
            : null,
      ),
    );
  }

  void _cancelBooking(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Booking?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestore.updateBookingStatus(id, 'cancelled');
    }
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onCancel;
  final VoidCallback? onRate;
  final VoidCallback? onProviderTap;

  const _BookingCard(
      {required this.booking, this.onCancel, this.onRate, this.onProviderTap});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border: const Border(bottom: BorderSide(color: AppTheme.divider)),
            ),
            child: Row(
              children: [
                booking.providerImage.isNotEmpty
                    ? GestureDetector(
                        onTap: onProviderTap,
                        child: CircleAvatar(
                          radius: 22,
                          backgroundImage: NetworkImage(booking.providerImage),
                          backgroundColor: AppTheme.divider,
                        ),
                      )
                    : GestureDetector(
                        onTap: onProviderTap,
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                          child: Text(
                            booking.providerName.isNotEmpty
                                ? booking.providerName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onProviderTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(booking.providerName,
                                  style: const TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.w700)),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                size: 12, color: AppTheme.textLight),
                          ],
                        ),
                        Text(booking.serviceType,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                StatusBadge(status: booking.status),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  text: DateFormat('EEEE, d MMM yyyy — h:mm a')
                      .format(booking.scheduledDate),
                ),
                const SizedBox(height: 8),
                _DetailRow(
                    icon: Icons.location_on_outlined, text: booking.address),
                if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _DetailRow(
                      icon: Icons.note_outlined, text: booking.notes!),
                ],
                const SizedBox(height: 12),
                const Divider(color: AppTheme.divider, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹${booking.amount.toInt()}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary)),
                    Row(
                      children: [
                        if (booking.status == 'completed')
                          booking.isRated
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.check_circle_rounded,
                                        size: 16, color: AppTheme.success),
                                    SizedBox(width: 4),
                                    Text('Rated',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.success,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                )
                              : OutlinedButton(
                                  onPressed: onRate,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    side: const BorderSide(
                                        color: AppTheme.primary),
                                    foregroundColor: AppTheme.primary,
                                  ),
                                  child: const Text('Rate',
                                      style: TextStyle(fontSize: 13)),
                                ),
                        if (onCancel != null) ...[
                          OutlinedButton(
                            onPressed: onCancel,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              foregroundColor: AppTheme.error,
                              side: const BorderSide(color: AppTheme.error),
                            ),
                            child: const Text('Cancel',
                                style: TextStyle(fontSize: 13)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                            ),
                            child: const Text('Track',
                                style: TextStyle(fontSize: 13)),
                          ),
                        ],
                        if (booking.status == 'in_progress')
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.my_location_rounded,
                                size: 16),
                            label: const Text('Track Live'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow({required this.icon, required this.text});

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
                  fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),
        ),
      ],
    );
  }
}