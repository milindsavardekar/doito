import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/models.dart';
import '../../services/firebase_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// Shows a bottom sheet letting the customer rate a completed booking's
/// service provider. Call this instead of building the UI inline so the
/// same flow can be triggered from anywhere (bookings list, etc.).
Future<void> showRateBookingSheet(BuildContext context, Booking booking) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RateBookingSheet(booking: booking),
  );
}

class _RateBookingSheet extends StatefulWidget {
  final Booking booking;
  const _RateBookingSheet({required this.booking});

  @override
  State<_RateBookingSheet> createState() => _RateBookingSheetState();
}

class _RateBookingSheetState extends State<_RateBookingSheet> {
  int _stars = 5;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  final _firestore = FirestoreService();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final providerId = widget.booking.providerId;
    if (uid == null || providerId == null || providerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to submit review right now')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _firestore.submitReview(
        bookingId: widget.booking.id,
        providerId: providerId,
        listingId: widget.booking.listingId,
        userId: uid,
        userName: FirebaseAuth.instance.currentUser?.displayName ?? 'Customer',
        rating: _stars.toDouble(),
        comment: _commentCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for your feedback!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Rate ${widget.booking.providerName}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(widget.booking.serviceType,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 20),

            // ── Star picker ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _stars;
                return GestureDetector(
                  onTap: () => setState(() => _stars = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppTheme.accent,
                      size: 38,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _ratingLabel(_stars),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 20),

            // ── Comment ──
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share your experience (optional)',
                hintStyle:
                    const TextStyle(color: AppTheme.textLight, fontSize: 13),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 20),

            GradientButton(
              label: 'Submit Review',
              isLoading: _submitting,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int stars) {
    switch (stars) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      default:
        return 'Excellent';
    }
  }
}
