import 'package:flutter/material.dart';

import '../config/aqua_colors.dart';

class StatusChip extends StatelessWidget {
  final String? status;
  const StatusChip({super.key, this.status});

  @override
  Widget build(BuildContext context) {
    final value = (status ?? 'unknown').toLowerCase();
    final color = AquaColors.forStatus(value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AquaColors.radius),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
