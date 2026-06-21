import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/models.dart';
import '../../services/firebase_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// Shows a bottom sheet letting a PROVIDER rate the CUSTOMER on a
/// completed booking. This is provider-only — never shown anywhere in the
/// customer-facing flow, and the rating it submits is never displayed back
/// to the customer (see [FirestoreService.submitCustomerRating]).
Future<void> showRateCustomerSheet(BuildContext context, Booking booking) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RateCustomerSheet(booking: booking),
  );
}

class _RateCustomerSheet extends StatefulWidget {
  final Booking booking;
  const _RateCustomerSheet({required this.booking});

  @override
  State<_RateCustomerSheet> createState() => _RateCustomerSheetState();
}

class _RateCustomerSheetState extends State<_RateCustomerSheet> {
  int _stars = 5;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  final _firestore = FirestoreService();

  String get _customerLabel =>
      (widget.booking.customerName?.trim().isNotEmpty ?? false)
          ? widget.booking.customerName!.trim()
          : 'this customer';

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final providerUid = FirebaseAuth.instance.currentUser?.uid;
    final customerId = widget.booking.userId;
    if (providerUid == null || customerId == null || customerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to submit rating right now')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _firestore.submitCustomerRating(
        bookingId: widget.booking.id,
        customerId: customerId,
        providerId: providerUid,
        providerName: widget.booking.providerName,
        rating: _stars.toDouble(),
        comment: _commentCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer rating saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit rating: $e')),
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
            Text('Rate $_customerLabel',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(widget.booking.serviceType,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 13, color: AppTheme.primary),
                  SizedBox(width: 6),
                  Text(
                    'Only visible to other providers — never shown to the customer',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
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
                hintText: 'Notes about this customer (optional)',
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
              label: 'Submit Rating',
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
        return 'Difficult';
      case 2:
        return 'Below Average';
      case 3:
        return 'Average';
      case 4:
        return 'Good';
      default:
        return 'Excellent';
    }
  }
}
