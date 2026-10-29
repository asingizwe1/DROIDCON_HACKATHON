/// A pond inspection.
///
/// The numeric water-quality readings are all nullable because an inspection
/// may only record some of them. `notes` is the free-text field that search
/// runs against.
class Inspection {
  final String id;
  final String farmerId;
  final String pondId;
  final String pondName;
  final String? farmName;
  final String? species;

  /// Unix seconds. Stored as an int because that is the Typesense field type.
  final int inspectionDate;
  final String notes;
  final String? status;
  final int? mortalityCount;
  final double? dissolvedOxygen;
  final double? waterTemperature;
  final double? ph;
  final double? ammonia;

  const Inspection({
    required this.id,
    required this.farmerId,
    required this.pondId,
    required this.pondName,
    required this.inspectionDate,
    required this.notes,
    this.farmName,
    this.species,
    this.status,
    this.mortalityCount,
    this.dissolvedOxygen,
    this.waterTemperature,
    this.ph,
    this.ammonia,
  });

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(
        inspectionDate * 1000,
      );

  factory Inspection.fromJson(Map<String, dynamic> json) => Inspection(
        id: json['id']?.toString() ?? '',
        farmerId: json['farmer_id']?.toString() ?? '',
        pondId: json['pond_id']?.toString() ?? '',
        pondName: json['pond_name']?.toString() ?? '',
        farmName: json['farm_name']?.toString(),
        species: json['species']?.toString(),
        inspectionDate: _toInt(json['inspection_date']) ?? 0,
        notes: json['notes']?.toString() ?? '',
        status: json['status']?.toString(),
        mortalityCount: _toInt(json['mortality_count']),
        dissolvedOxygen: _toDouble(json['dissolved_oxygen']),
        waterTemperature: _toDouble(json['water_temperature']),
        ph: _toDouble(json['ph']),
        ammonia: _toDouble(json['ammonia']),
      );

  /// The document sent to Typesense. Field names match the collection schema
  /// exactly, and missing readings are omitted rather than sent as null.
  Map<String, dynamic> toIndexDocument() {
    final doc = <String, dynamic>{
      'id': id,
      'farmer_id': farmerId,
      'pond_id': pondId,
      'pond_name': pondName,
      'inspection_date': inspectionDate,
      'notes': notes,
    };
    if (farmName != null) doc['farm_name'] = farmName;
    if (species != null) doc['species'] = species;
    if (status != null) doc['status'] = status;
    if (mortalityCount != null) doc['mortality_count'] = mortalityCount;
    if (dissolvedOxygen != null) doc['dissolved_oxygen'] = dissolvedOxygen;
    if (waterTemperature != null) doc['water_temperature'] = waterTemperature;
    if (ph != null) doc['ph'] = ph;
    if (ammonia != null) doc['ammonia'] = ammonia;
    return doc;
  }
}

/// One search result: the inspection plus the marked-up snippet Typesense
/// returned for it.
class InspectionSearchResult {
  final Inspection inspection;

  /// The matched text with `<mark>` tags around hits, as Typesense returns it.
  final String snippet;

  const InspectionSearchResult({
    required this.inspection,
    required this.snippet,
  });
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}
