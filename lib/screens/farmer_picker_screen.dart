import 'package:flutter/material.dart';

import '../config/aqua_colors.dart';

/// Stands in for login. The demo has two farmers, each with their own farms,
/// ponds and inspections, so the scoped-search isolation is demonstrable.
class FarmerPickerScreen extends StatelessWidget {
  final void Function(String farmerId, String farmerName) onPick;

  const FarmerPickerScreen({super.key, required this.onPick});

  static const List<({String id, String name, String detail})> demos = [
    (
      id: 'farmer_1',
      name: 'Amina Nakato',
      detail: 'Lakeview Fish Farm • Wakiso • 3 ponds',
    ),
    (
      id: 'farmer_2',
      name: 'Joseph Okello',
      detail: 'Riverside Aquaculture • Jinja • 2 ponds',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AquaColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.water,
                    size: 32, color: AquaColors.primary),
              ),
              const SizedBox(height: 20),
              const Text(
                'AquaFarm',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Fish farm inspections with instant history search.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'CONTINUE AS',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AquaColors.accent,
                ),
              ),
              const SizedBox(height: 10),
              ...demos.map(
                (demo) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AquaColors.radius),
                      side: BorderSide(
                          color: Colors.black.withValues(alpha: 0.1)),
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AquaColors.radius),
                      ),
                      onTap: () => onPick(demo.id, demo.name),
                      leading: CircleAvatar(
                        backgroundColor:
                            AquaColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          demo.name[0],
                          style: const TextStyle(
                            color: AquaColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(
                        demo.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(demo.detail),
                      trailing: const Icon(Icons.arrow_forward),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'No sign-up needed for this demo. Sign-in, and the real '
                'per-farmer session token that would replace it, are out of '
                'scope for the hackathon build.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
