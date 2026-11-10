import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/booking.dart';

/**
 * Standard status badge for booking reservations.
 */
class BkBookingStatusChip extends StatelessWidget {
  final BookingStatus status;

  const BkBookingStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case BookingStatus.CONFIRMED:
        bg = AppTheme.brandColor.withOpacity(0.12);
        fg = AppTheme.brandColor;
        label = 'CONFIRMED';
        break;
      case BookingStatus.PENDING:
        bg = AppTheme.accentColor.withOpacity(0.18);
        fg = const Color(0xFFB48329); // Rich champagne gold tone
        label = 'PENDING';
        break;
      case BookingStatus.COMPLETED:
        bg = const Color(0xFF2563EB).withOpacity(0.12);
        fg = const Color(0xFF1D4ED8);
        label = 'COMPLETED';
        break;
      case BookingStatus.CANCELLED:
        bg = AppTheme.errorColor.withOpacity(0.12);
        fg = AppTheme.errorColor;
        label = 'CANCELLED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/**
 * High-legibility price display formatted according to Back2Kasi standards.
 */
class BkPriceDisplay extends StatelessWidget {
  final double pricePerDay;
  final double fontSize;
  final Color? color;
  final String period;

  const BkPriceDisplay({
    super.key,
    required this.pricePerDay,
    this.fontSize = 20,
    this.color,
    this.period = '/day',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'R ${pricePerDay.toStringAsFixed(pricePerDay % 1 == 0 ? 0 : 2)}',
          style: TextStyle(
            color: color ?? AppTheme.brandColor,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          period,
          style: const TextStyle(
            color: AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

