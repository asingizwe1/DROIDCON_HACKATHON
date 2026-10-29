import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/inspection_search_service.dart';
import '../config/app_config.dart';
import '../config/aqua_colors.dart';
import '../models/inspection.dart';
import '../screens/inspection_detail_screen.dart';
import '../widgets/highlighted_text.dart';
import '../widgets/status_chip.dart';

/// Inspection history search.
///
/// Queries Typesense through a farmer-scoped key. If the search service is
/// unreachable or the device is offline, it filters the already-loaded
/// inspections locally so the farmer still gets an answer, and says so.
class InspectionSearchScreen extends StatefulWidget {
  /// The farmer whose inspections are searchable. Comes from the session.
  final String farmerId;

  /// Every inspection already loaded by the app. Used for the offline
  /// fallback and for showing something before the first query runs.
  final List<Inspection> loadedInspections;

  /// Optionally restrict search to one pond.
  final String? pondId;

  const InspectionSearchScreen({
    super.key,
    required this.farmerId,
    this.loadedInspections = const [],
    this.pondId,
  });

  @override
  State<InspectionSearchScreen> createState() => _InspectionSearchScreenState();
}

class _InspectionSearchScreenState extends State<InspectionSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _debounce;

  /// Monotonic ticket so a slow earlier response can never overwrite the
  /// results of a later keystroke.
  int _requestId = 0;

  bool _loading = false;
  bool _offlineSearch = false;
  String? _error;
  String _activeQuery = '';
  List<InspectionSearchResult> _results = const [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    final text = _controller.text;
    _debounce?.cancel();
    if (text.trim().isEmpty) {
      setState(() {
        _results = const [];
        _loading = false;
        _error = null;
        _offlineSearch = false;
        _activeQuery = '';
      });
      return;
    }
    // Debounced so we do not fire a search on every keystroke.
    _debounce = Timer(AppConfig.searchDebounce, () => _runSearch(text));
  }

  Future<void> _runSearch(String raw) async {
    final query = raw.trim();
    if (query.isEmpty) return;

    final ticket = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await InspectionSearchService.instance.search(
        query,
        farmerId: widget.farmerId,
        pondId: widget.pondId,
      );
      if (!mounted || ticket != _requestId) return;
      setState(() {
        _results = results;
        _activeQuery = query;
        _loading = false;
        _offlineSearch = false;
      });
    } on SearchException catch (e) {
      if (!mounted || ticket != _requestId) return;
      if (e.isUnavailable) {
        // Search is down: answer from what we already have, and label it.
        setState(() {
          _results = _localSearch(query);
          _activeQuery = query;
          _loading = false;
          _offlineSearch = true;
          _error = null;
        });
      } else {
        setState(() {
          _loading = false;
          _error = e.message;
          _results = const [];
        });
      }
    } catch (_) {
      if (!mounted || ticket != _requestId) return;
      setState(() {
        _results = _localSearch(query);
        _activeQuery = query;
        _loading = false;
        _offlineSearch = true;
      });
    }
  }

  /// Case-insensitive local fallback over the inspections already in memory.
  List<InspectionSearchResult> _localSearch(String query) {
    final needle = query.toLowerCase();
    return widget.loadedInspections
        .where((i) =>
            i.notes.toLowerCase().contains(needle) ||
            i.pondName.toLowerCase().contains(needle) ||
            (i.species ?? '').toLowerCase().contains(needle))
        .map((i) => InspectionSearchResult(inspection: i, snippet: i.notes))
        .toList()
      ..sort((a, b) => b.inspection.inspectionDate
          .compareTo(a.inspection.inspectionDate));
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AquaColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Search inspections'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: _runSearch,
              decoration: InputDecoration(
                hintText: 'Try "ammonea", "fin rot", "tilapia"',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear',
                        onPressed: _clear,
                      ),
                filled: true,
                fillColor: AquaColors.fieldFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AquaColors.radius),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AquaColors.radius),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AquaColors.radius),
                  borderSide: const BorderSide(color: AquaColors.primary),
                ),
              ),
            ),
          ),
          if (_offlineSearch) _offlineBanner(),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }

  Widget _offlineBanner() {
    return Container(
      width: double.infinity,
      color: AquaColors.attention.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 16, color: AquaColors.attention),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline search — matching only what is already saved on this device.',
              style: TextStyle(
                fontSize: 12,
                color: AquaColors.attention.withValues(alpha: 0.95),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_controller.text.trim().isEmpty) {
      return _emptyState(
        icon: Icons.search,
        title: 'Search your inspection history',
        subtitle:
            'Find any past pond inspection by what you wrote in the notes, '
            'the pond name, or the species. Typos are fine.',
      );
    }
    if (_loading && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _errorState(_error!);
    }
    if (_results.isEmpty) {
      return _emptyState(
        icon: Icons.search_off,
        title: 'No inspections match "$_activeQuery"',
        subtitle: 'Try a shorter word, or a different spelling.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        return _resultCard(context, result);
      },
    );
  }

  Widget _resultCard(BuildContext context, InspectionSearchResult result) {
    final inspection = result.inspection;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AquaColors.radius),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AquaColors.radius),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InspectionDetailScreen(inspection: inspection),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      inspection.pondName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  StatusChip(status: inspection.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                [
                  if (inspection.species != null)
                    _capitalize(inspection.species!),
                  DateFormat('MMM d, yyyy').format(inspection.date),
                ].join(' • '),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 8),
              HighlightedText(result.snippet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 44, color: Colors.black26),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black.withValues(alpha: 0.55)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 44, color: AquaColors.critical),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AquaColors.primary,
              ),
              onPressed: () => _runSearch(_controller.text),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
