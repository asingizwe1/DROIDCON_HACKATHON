import 'dart:async';

import 'package:flutter/material.dart';

import '../api/farm_api.dart';
import '../config/aqua_colors.dart';
import '../models/farm.dart';
import '../models/inspection.dart';
import '../widgets/status_chip.dart';
import 'inspection_detail_screen.dart';
import 'inspection_search_screen.dart';

/// One farm: its ponds, and the inspections recorded against them.
class FarmDetailScreen extends StatefulWidget {
  final String farmerId;
  final Farm farm;

  const FarmDetailScreen({
    super.key,
    required this.farmerId,
    required this.farm,
  });

  @override
  State<FarmDetailScreen> createState() => _FarmDetailScreenState();
}

class _FarmDetailScreenState extends State<FarmDetailScreen> {
  late FarmApi _api;
  bool _loading = true;
  String? _error;
  List<Pond> _ponds = const [];
  List<Inspection> _inspections = const [];

  @override
  void initState() {
    super.initState();
    _api = FarmApi(widget.farmerId);
    _load();
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
      final ponds = await _api.ponds(farmId: widget.farm.id);
      final inspections = await _api.inspections();
      if (!mounted) return;
      setState(() {
        _ponds = ponds;
        _inspections =
            inspections.where((i) => ponds.any((p) => p.id == i.pondId)).toList();
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

  List<Inspection> _forPond(String pondId) => _inspections
      .where((i) => i.pondId == pondId)
      .toList()
    ..sort((a, b) => b.inspectionDate.compareTo(a.inspectionDate));

  void _openSearch({String? pondId}) {
    // The pond's species is copied onto each inspection as it is created, so
    // the loaded list is already enough for the offline fallback.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InspectionSearchScreen(
          farmerId: widget.farmerId,
          loadedInspections: _inspections,
          pondId: pondId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.farm.name),
        backgroundColor: AquaColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search this farm\'s inspections',
            onPressed: _loading ? null : () => _openSearch(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  color: AquaColors.primary,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      ..._ponds.map(_pondCard),
                      if (_inspections.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              const Icon(Icons.description_outlined,
                                  size: 40, color: Colors.black26),
                              const SizedBox(height: 10),
                              Text(
                                'No inspections recorded yet.',
                                style: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _pondCard(Pond pond) {
    final inspections = _forPond(pond.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AquaColors.radius),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.water, size: 18, color: AquaColors.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      pond.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  StatusChip(status: pond.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${_capitalize(pond.species)} • ${pond.stockCount} fish • '
                '${pond.areaM2.toStringAsFixed(0)} m² • '
                '${pond.depthM.toStringAsFixed(1)} m deep',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${inspections.length} inspection'
                    '${inspections.length == 1 ? "" : "s"}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (inspections.isNotEmpty)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AquaColors.accent,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.search, size: 16),
                      label: const Text('Search'),
                      onPressed: () => _openSearch(pondId: pond.id),
                    ),
                ],
              ),
              const Divider(height: 12),
              if (inspections.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No inspections yet for this pond.',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                )
              else
                ...inspections.take(3).map(
                      (inspection) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.fact_check_outlined,
                            size: 18, color: AquaColors.primary),
                        title: Text(
                          _formatDate(inspection),
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          inspection.notes,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                InspectionDetailScreen(inspection: inspection),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(Inspection inspection) {
    final d = inspection.date;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    final mm = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year} • $h:$mm $ampm';
  }

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
