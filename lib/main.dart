import 'package:flutter/material.dart';

import 'config/aqua_colors.dart';
import 'screens/farmer_picker_screen.dart';
import 'screens/root_shell.dart';

void main() {
  runApp(const AquaFarmApp());
}

class AquaFarmApp extends StatefulWidget {
  const AquaFarmApp({super.key});

  @override
  State<AquaFarmApp> createState() => _AquaFarmAppState();
}

class _AquaFarmAppState extends State<AquaFarmApp> {
  /// Empty until a demo farmer is picked. There is no login in this build.
  String _farmerId = '';
  String _farmerName = '';

  void _pick(String id, String name) {
    setState(() {
      _farmerId = id;
      _farmerName = name;
    });
  }

  void _switchFarmer(String id, String name) => _pick(id, name);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaFarm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AquaColors.primary,
          primary: AquaColors.primary,
          secondary: AquaColors.accent,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        cardTheme: const CardThemeData(color: Colors.white),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AquaColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AquaColors.radius),
            ),
          ),
        ),
      ),
      home: _farmerId.isEmpty
          ? FarmerPickerScreen(onPick: _pick)
          : RootShell(
              farmerId: _farmerId,
              farmerName: _farmerName,
              onSwitchFarmer: _switchFarmer,
            ),
    );
  }
}
