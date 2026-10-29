class Farm {
  final String id;
  final String farmerId;
  final String name;
  final String district;
  final double? latitude;
  final double? longitude;
  final int pondCount;

  const Farm({
    required this.id,
    required this.farmerId,
    required this.name,
    required this.district,
    this.latitude,
    this.longitude,
    this.pondCount = 0,
  });

  factory Farm.fromJson(Map<String, dynamic> json) => Farm(
        id: json['id']?.toString() ?? '',
        farmerId: json['farmer_id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unnamed farm',
        district: json['district']?.toString() ?? '',
        latitude: _toDouble(json['latitude']),
        longitude: _toDouble(json['longitude']),
        pondCount: _toInt(json['pond_count']) ?? 0,
      );
}

class Pond {
  final String id;
  final String farmerId;
  final String farmId;
  final String name;
  final String species;
  final double areaM2;
  final double depthM;
  final int stockCount;
  final String status;

  const Pond({
    required this.id,
    required this.farmerId,
    required this.farmId,
    required this.name,
    required this.species,
    this.areaM2 = 0,
    this.depthM = 0,
    this.stockCount = 0,
    this.status = 'healthy',
  });

  factory Pond.fromJson(Map<String, dynamic> json) => Pond(
        id: json['id']?.toString() ?? '',
        farmerId: json['farmer_id']?.toString() ?? '',
        farmId: json['farm_id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unnamed pond',
        species: json['species']?.toString() ?? '',
        areaM2: _toDouble(json['area_m2']) ?? 0,
        depthM: _toDouble(json['depth_m']) ?? 0,
        stockCount: _toInt(json['stock_count']) ?? 0,
        status: json['status']?.toString() ?? 'healthy',
      );
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
