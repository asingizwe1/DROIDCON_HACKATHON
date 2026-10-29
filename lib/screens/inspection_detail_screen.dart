import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/aqua_colors.dart';
import '../models/inspection.dart';
import '../widgets/status_chip.dart';

/// The one place a past inspection is shown in full. Both the inspection list
/// and the search results open this, so there is no second copy of the detail
/// view to keep in sync.
class InspectionDetailScreen extends StatelessWidget {
  final Inspection inspection;

  const InspectionDetailScreen({super.key, required this.inspection});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(inspection.pondName),
        backgroundColor: AquaColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d yyyy • h:mm a')
                          .format(inspection.date),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (inspection.farmName != null) inspection.farmName!,
                        if (inspection.species != null)
                          '${_capitalize(inspection.species!)} stock',
                      ].join(' • '),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              StatusChip(status: inspection.status),
            ],
          ),
          const SizedBox(height: 20),
          _section(context, 'Notes', Text(inspection.notes)),
          const SizedBox(height: 20),
          _section(context, 'Water quality', _readings(context)),
          if (inspection.mortalityCount != null) ...[
            const SizedBox(height: 20),
            _section(
              context,
              'Mortality',
              Text(
                '${inspection.mortalityCount} fish',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: (inspection.mortalityCount ?? 0) > 0
                          ? AquaColors.critical
                          : AquaColors.healthy,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.1,
                color: AquaColors.accent,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _readings(BuildContext context) {
    final rows = <(String, String?)>[
      ('Water temp', _fmt(inspection.waterTemperature, '°C')),
      ('Dissolved O₂', _fmt(inspection.dissolvedOxygen, ' mg/L')),
      ('pH', _fmt(inspection.ph, '')),
      ('Ammonia', _fmt(inspection.ammonia, ' mg/L')),
    ].where((r) => r.$2 != null).toList();

    if (rows.isEmpty) {
      return const Text('No readings recorded for this inspection.');
    }

    return Container(
      decoration: BoxDecoration(
        color: AquaColors.fieldFill.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AquaColors.radius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(row.$1),
                  Text(
                    row.$2!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String? _fmt(double? value, String unit) =>
      value == null ? null : '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}$unit';

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
