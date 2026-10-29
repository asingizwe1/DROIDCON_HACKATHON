import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/farm_api.dart';
import '../config/aqua_colors.dart';
import '../models/farm.dart';
import '../models/inspection.dart';
import '../widgets/status_chip.dart';
import 'farm_detail_screen.dart';

/// Landing screen: the farms this farmer manages, then their latest
/// inspections. Deliberately no login — a demo farmer is chosen up front.
class HomeScreen extends StatefulWidget {
  final String farmerId;
  final String farmerName;
  final void Function(String farmerId, String farmerName) onSwitchFarmer;

  const HomeScreen({
    super.key,
    required this.farmerId,
    required this.farmerName,
    required this.onSwitchFarmer,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FarmApi _api;
  bool _loading = true;
  String? _error;
  List<Farm> _farms = const [];
  List<Inspection> _recentInspections = const [];

  @override
  void initState() {
    super.initState();
    _api = FarmApi(widget.farmerId);
    _load();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.farmerId != widget.farmerId) {
      _api.close();
      _api = FarmApi(widget.farmerId);
      _load();
    }
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final farms = await _api.farms();
      final inspections = await _api.inspections();
      if (!mounted) return;
      setState(() {
        _farms = farms;
        _recentInspections = inspections;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AquaColors.primary,
      onRefresh: _load,
      child: Scaffold(
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _errorBody(_error!)
                : ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      _header(context),
                      if (_farms.isNotEmpty) _farmsSection(context),
                      if (_recentInspections.isNotEmpty)
                        _recentSection(context),
                    ],
                  ),
      ),
    );
  }

  Widget _errorBody(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 44, color: AquaColors.critical),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: AquaColors.primary),
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AquaColors.primary,
            AquaColors.primary.withValues(alpha: 0.82),
            AquaColors.accent.withValues(alpha: 0.55),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                'AquaFarm',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Hello, ${widget.farmerName.split(' ').first}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_farms.length} ${_farms.length == 1 ? "farm" : "farms"} • '
            '${_recentInspections.length} inspections recorded',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }

  Widget _farmsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Your farms'),
        ..._farms.map(
          (farm) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AquaColors.radius),
                side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AquaColors.radius),
                ),
                leading: CircleAvatar(
                  backgroundColor:
                      AquaColors.accent.withValues(alpha: 0.12),
                  child: const Icon(Icons.waves, color: AquaColors.accent),
                ),
                title: Text(
                  farm.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${farm.district} • ${farm.pondCount} '
                  '${farm.pondCount == 1 ? "pond" : "ponds"}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FarmDetailScreen(
                      farmerId: widget.farmerId,
                      farm: farm,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _recentSection(BuildContext context) {
    final recent = [..._recentInspections]
      ..sort((a, b) => b.inspectionDate.compareTo(a.inspectionDate));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Recent inspections'),
        ...recent.take(5).map(
              (inspection) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AquaColors.radius),
                    side:
                        BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                inspection.pondName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            StatusChip(status: inspection.status),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM d, yyyy')
                              .format(inspection.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          inspection.notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }
}
