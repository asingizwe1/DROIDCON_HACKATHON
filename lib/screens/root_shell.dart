import 'package:flutter/material.dart';

import '../api/inspection_search_service.dart';
import '../config/aqua_colors.dart';
import 'home_screen.dart';
import 'inspection_search_screen.dart';

/// Holds the selected demo farmer and switches between the two tabs.
class RootShell extends StatefulWidget {
  final String farmerId;
  final String farmerName;
  final void Function(String farmerId, String farmerName) onSwitchFarmer;

  const RootShell({
    super.key,
    required this.farmerId,
    required this.farmerName,
    required this.onSwitchFarmer,
  });

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  void didUpdateWidget(covariant RootShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.farmerId != widget.farmerId) {
      // A scoped key is only valid for the farmer it was issued to.
      InspectionSearchService.instance.clearCache();
    }
  }

  Future<void> _confirmSwitch() async {
    final sw = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch farmer'),
        content: const Text(
          'Search keys are scoped to one farmer. Switching clears the '
          'cached search key.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );
    if (sw == true) widget.onSwitchFarmer('', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AquaFarm',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AquaColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Switch farmer',
            icon: const Icon(Icons.switch_account),
            onPressed: _confirmSwitch,
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            farmerId: widget.farmerId,
            farmerName: widget.farmerName,
            onSwitchFarmer: widget.onSwitchFarmer,
          ),
          InspectionSearchScreen(farmerId: widget.farmerId),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: AquaColors.primary.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AquaColors.primary),
            label: 'Farms',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search, color: AquaColors.primary),
            label: 'Search',
          ),
        ],
      ),
    );
  }
}
