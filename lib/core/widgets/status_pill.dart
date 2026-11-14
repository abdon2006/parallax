import 'package:flutter/material.dart';
import 'package:parallax/core/constants/app_colors.dart';

Color statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'recommended':
      return AppColors.recommended;
    case 'acceptable':
      return AppColors.acceptable;
    default:
      return AppColors.notRecommended;
  }
}

Color warningColor(String level) {
  switch (level.toLowerCase()) {
    case 'high':
      return AppColors.warningHigh;
    case 'caution':
      return AppColors.warningCaution;
    case 'none':
      return AppColors.warningNone;
    default:
      return AppColors.textMuted;
  }
}

class StatusPill extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusPill({super.key, required this.status, this.fontSize = 10});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class WarningPill extends StatelessWidget {
  final String level;

  const WarningPill({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final color = warningColor(level);
    final label = switch (level.toLowerCase()) {
      'high' => 'High warning',
      'caution' => 'Caution',
      'none' => 'No warning',
      _ => 'No rating',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
