import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/firebase_services.dart';
import '../../theme/app_theme.dart';

/// Shows a bottom sheet listing every rating + comment other providers have
/// left about [customerId], newest first. Opened by tapping a customer's
/// name/rating badge on a booking card (provider-only, mirrors how reviews
/// are shown on a provider's public profile).
Future<void> showCustomerRatingsSheet(
  BuildContext context, {
  required String customerId,
  required String customerName,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CustomerRatingsSheet(
      customerId: customerId,
      customerName: customerName,
    ),
  );
}

class _CustomerRatingsSheet extends StatelessWidget {
  final String customerId;
  final String customerName;
  const _CustomerRatingsSheet({
    required this.customerId,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 14),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Ratings for $customerName',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'From other providers — only visible to providers',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<CustomerRating>>(
                  stream:
                      FirestoreService().getCustomerRatings(customerId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primary));
                    }
                    final ratings = snapshot.data!;
                    if (ratings.isEmpty) {
                      return const Center(
                        child: Text('No ratings yet',
                            style: TextStyle(color: AppTheme.textSecondary)),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: ratings.length,
                      itemBuilder: (_, i) =>
                          _CustomerRatingCard(rating: ratings[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CustomerRatingCard extends StatelessWidget {
  final CustomerRating rating;
  const _CustomerRatingCard({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    rating.providerName.isNotEmpty
                        ? rating.providerName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rating.providerName,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    if (rating.createdAt != null)
                      Text(
                        DateFormat('d MMM yyyy').format(rating.createdAt!),
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textLight),
                      ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating.rating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14,
                    color: AppTheme.accent,
                  );
                }),
              ),
            ],
          ),
          if (rating.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              rating.comment.trim(),
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
