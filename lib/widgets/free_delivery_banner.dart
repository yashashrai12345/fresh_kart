import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class FreeDeliveryBanner extends StatelessWidget {
  final double subtotal;
  final double threshold;

  const FreeDeliveryBanner({
    super.key,
    required this.subtotal,
    required this.threshold,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (threshold - subtotal).clamp(0.0, threshold);
    final progress = (subtotal / threshold).clamp(0.0, 1.0);
    final isUnlocked = subtotal >= threshold && subtotal > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUnlocked ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isUnlocked ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isUnlocked
                    ? Icons.check_circle_rounded
                    : Icons.local_shipping_rounded,
                size: 18,
                color: isUnlocked
                    ? const Color(0xFF15803D)
                    : const Color(0xFFB45309),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isUnlocked
                      ? 'Congratulations! You unlocked FREE delivery 🎉'
                      : 'Add ₹${remaining.toStringAsFixed(0)} more for FREE delivery!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isUnlocked
                        ? const Color(0xFF15803D)
                        : const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isUnlocked
                  ? const Color(0xFFBBF7D0)
                  : const Color(0xFFFDE68A),
              valueColor: AlwaysStoppedAnimation<Color>(
                isUnlocked ? AppTheme.primary : AppTheme.accentWarm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
