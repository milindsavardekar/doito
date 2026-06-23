import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/models.dart';
import '../../services/firebase_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class BookingScreen extends StatefulWidget {
  /// Pass either a [listing] (from Services tab) OR a [provider] (from Explore/Home)
  final ServiceListing? listing;
  final ServiceProvider? provider;

  const BookingScreen({super.key, this.listing, this.provider})
      : assert(listing != null || provider != null,
            'Provide either listing or provider');

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '10:00 AM';
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _confirming = false;
  bool _booked = false;

  final _firestore = FirestoreService();

  final List<String> _timeSlots = [
    '8:00 AM', '9:00 AM', '10:00 AM', '11:00 AM',
    '12:00 PM', '2:00 PM', '3:00 PM', '4:00 PM', '5:00 PM',
  ];

  // ── Derived display values — always from real data ──────────────────────────
  String get _serviceName =>
      widget.listing?.title ??
      '${widget.provider!.category} Service';

  String get _providerName =>
      widget.listing?.providerName ?? widget.provider!.name;

  String get _providerInitial =>
      _providerName.isNotEmpty ? _providerName[0].toUpperCase() : '?';

  String get _categoryLabel =>
      widget.listing?.category ?? widget.provider!.category;

  /// Exact price — no multipliers, no guessing
  double get _servicePrice =>
      widget.listing?.price ?? widget.provider!.pricePerHour;

  String get _priceLabel =>
      widget.listing?.priceUnit ?? 'per hour';

  String get _providerId =>
      widget.listing?.providerId ?? widget.provider!.id;

  double get _platformFee => 29;
  double get _total => _servicePrice + _platformFee;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _confirmBooking() async {
    if (_addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your address')),
      );
      return;
    }
    setState(() => _confirming = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final customerName =
          FirebaseAuth.instance.currentUser?.displayName?.trim();
      await _firestore.addBooking(Booking(
        id: '',
        serviceType: _serviceName,
        providerName: _providerName,
        providerImage: widget.provider?.imageUrl ?? '',
        scheduledDate: _selectedDate,
        status: 'confirmed',
        amount: _total,
        address: _addressCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        providerId: _providerId,
        userId: uid,
        customerName: (customerName == null || customerName.isEmpty)
            ? null
            : customerName,
        listingId: widget.listing?.id,
      ));
      if (mounted) setState(() { _confirming = false; _booked = true; });
    } catch (e) {
      if (mounted) {
        setState(() => _confirming = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Booking failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(_booked ? 'Booking Confirmed!' : 'Book Service'),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: AppTheme.appBarTitleStyle(color: Colors.white),
      ),
      body: _booked ? _buildSuccess() : _buildForm(),
    );
  }

  // ── Form ───────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Service summary header ────────────────────────────────────────
          Container(
            color: AppTheme.primary,
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12)
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                      child: Text(_providerInitial,
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_serviceName,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(_providerName,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary)),
                          Text(_categoryLabel,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${_servicePrice.toInt()}',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary)),
                        Text(_priceLabel,
                            style: const TextStyle(
                                fontSize: 10, color: AppTheme.textLight)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Date picker ─────────────────────────────────────────────
                _SectionCard(
                  title: 'Select Date',
                  child: SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 14,
                      itemBuilder: (_, i) {
                        final date =
                            DateTime.now().add(Duration(days: i + 1));
                        final sel = _selectedDate.day == date.day &&
                            _selectedDate.month == date.month;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedDate = date),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 64,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              gradient:
                                  sel ? AppTheme.accentGradient : null,
                              color: sel ? null : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: sel
                                      ? AppTheme.primary
                                      : AppTheme.divider),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(DateFormat('EEE').format(date),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: sel
                                            ? Colors.white70
                                            : AppTheme.textLight)),
                                const SizedBox(height: 4),
                                Text(DateFormat('d').format(date),
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: sel
                                            ? Colors.white
                                            : AppTheme.textPrimary)),
                                Text(DateFormat('MMM').format(date),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: sel
                                            ? Colors.white70
                                            : AppTheme.textLight)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // ── Time slots ──────────────────────────────────────────────
                _SectionCard(
                  title: 'Select Time',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _timeSlots.map((t) {
                      final sel = _selectedTime == t;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTime = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            gradient: sel ? AppTheme.accentGradient : null,
                            color: sel ? null : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: sel
                                    ? AppTheme.primary
                                    : AppTheme.divider),
                          ),
                          child: Text(t,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? Colors.white
                                      : AppTheme.textSecondary)),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // ── Address ─────────────────────────────────────────────────
                _SectionCard(
                  title: 'Service Address',
                  child: AppTextField(
                    label: '',
                    hint: 'House no., Street, Area, City',
                    controller: _addressCtrl,
                    prefixIcon: Icons.location_on_outlined,
                    maxLines: 2,
                  ),
                ),

                // ── Notes ───────────────────────────────────────────────────
                _SectionCard(
                  title: 'Special Instructions (Optional)',
                  child: AppTextField(
                    label: '',
                    hint: 'e.g. Call before arriving, Gate code...',
                    controller: _notesCtrl,
                    maxLines: 3,
                  ),
                ),

                // ── Price summary — real numbers only ───────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      _PriceRow(
                        label: _serviceName,
                        value: '₹${_servicePrice.toInt()}',
                        color: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      _PriceRow(
                        label: 'Platform Fee',
                        value: '₹${_platformFee.toInt()}',
                        color: Colors.white70,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Divider(
                            color: Colors.white.withValues(alpha: 0.3),
                            thickness: 1),
                      ),
                      _PriceRow(
                        label: 'Total Payable',
                        value: '₹${_total.toInt()}',
                        color: Colors.white,
                        isBold: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                GradientButton(
                  label: 'Confirm Booking  ·  ₹${_total.toInt()}',
                  onTap: _confirmBooking,
                  isLoading: _confirming,
                  icon: Icons.check_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Success ────────────────────────────────────────────────────────────────
  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 12))
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 50),
            ),
            const SizedBox(height: 28),
            const Text('Booking Confirmed! 🎉',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.6),
                children: [
                  TextSpan(
                      text: _providerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  const TextSpan(text: ' will arrive on\n'),
                  TextSpan(
                      text: DateFormat('EEEE, d MMM').format(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: ' at $_selectedTime'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Text(
                '₹${_servicePrice.toInt()}  +  ₹${_platformFee.toInt()} fee  =  ₹${_total.toInt()}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 32),
            GradientButton(
              label: 'View My Bookings',
              onTap: () => Navigator.pop(context),
              icon: Icons.calendar_today_rounded,
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: AppTheme.primary),
                foregroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isBold;
  const _PriceRow(
      {required this.label,
      required this.value,
      required this.color,
      this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: color,
                  fontSize: isBold ? 16 : 14,
                  fontWeight:
                      isBold ? FontWeight.w700 : FontWeight.w400)),
        ),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: isBold ? 20 : 14,
                fontWeight:
                    isBold ? FontWeight.w800 : FontWeight.w600)),
      ],
    );
  }
}
