import 'package:flutter_test/flutter_test.dart';
import 'package:aquafarm/models/inspection.dart';

void main() {
  group('Inspection', () {
    final json = <String, dynamic>{
      'id': 'insp_001',
      'farmer_id': 'farmer_1',
      'pond_id': 'pond_1',
      'pond_name': 'Pond A',
      'farm_name': 'Lakeview Fish Farm',
      'species': 'tilapia',
      'inspection_date': 1759000000,
      'notes': 'Ammonia elevated.',
      'status': 'attention',
      'mortality_count': 12,
      'dissolved_oxygen': 3.1,
      'water_temperature': 29.5,
      'ph': 7.8,
      'ammonia': 1.2,
    };

    test('fromJson reads every documented field', () {
      final i = Inspection.fromJson(json);
      expect(i.id, 'insp_001');
      expect(i.farmerId, 'farmer_1');
      expect(i.pondId, 'pond_1');
      expect(i.pondName, 'Pond A');
      expect(i.species, 'tilapia');
      expect(i.inspectionDate, 1759000000);
      expect(i.notes, 'Ammonia elevated.');
      expect(i.status, 'attention');
      expect(i.mortalityCount, 12);
      expect(i.dissolvedOxygen, 3.1);
      expect(i.waterTemperature, 29.5);
      expect(i.ph, 7.8);
      expect(i.ammonia, 1.2);
    });

    test('tolerates missing optional readings', () {
      final bare = Inspection.fromJson({
        'id': 'x',
        'farmer_id': 'farmer_1',
        'pond_id': 'pond_1',
        'pond_name': 'Pond A',
        'inspection_date': 1,
        'notes': '',
      });
      expect(bare.dissolvedOxygen, isNull);
      expect(bare.mortalityCount, isNull);
      expect(bare.status, isNull);
    });

    test('toIndexDocument omits nulls but keeps zeros', () {
      final doc = Inspection.fromJson({
        ...json,
        'dissolved_oxygen': null,
        'mortality_count': 0,
      }).toIndexDocument();

      expect(doc.containsKey('dissolved_oxygen'), isFalse);
      expect(doc['mortality_count'], 0);
      expect(doc['id'], 'insp_001');
      expect(doc['inspection_date'], isA<int>());
    });
  });
}
