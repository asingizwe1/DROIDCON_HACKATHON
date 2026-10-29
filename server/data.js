// Dummy aquaculture data. No database: this file IS the source of truth for
// the demo. The farm/pond/inspection ids here match what is seeded into
// Typesense by seed.js.

export const farmers = [
  {
    id: 'farmer_1',
    name: 'Amina Nakato',
    email: 'amina@lakeview.example',
    district: 'Wakiso',
  },
  {
    id: 'farmer_2',
    name: 'Joseph Okello',
    email: 'joseph@riverside.example',
    district: 'Jinja',
  },
];

export const farms = [
  {
    id: 'farm_1',
    farmer_id: 'farmer_1',
    name: 'Lakeview Fish Farm',
    district: 'Wakiso',
    latitude: 0.3961,
    longitude: 32.4821,
    pond_count: 3,
  },
  {
    id: 'farm_2',
    farmer_id: 'farmer_2',
    name: 'Riverside Aquaculture',
    district: 'Jinja',
    latitude: 0.4244,
    longitude: 33.2041,
    pond_count: 2,
  },
];

export const ponds = [
  { id: 'pond_1', farmer_id: 'farmer_1', farm_id: 'farm_1', name: 'Pond A', species: 'tilapia',      area_m2: 250, depth_m: 1.4, stock_count: 4200, status: 'attention' },
  { id: 'pond_2', farmer_id: 'farmer_1', farm_id: 'farm_1', name: 'Pond B', species: 'catfish',      area_m2: 400, depth_m: 1.8, stock_count: 6100, status: 'critical'  },
  { id: 'pond_3', farmer_id: 'farmer_1', farm_id: 'farm_1', name: 'Pond C', species: 'tilapia',      area_m2: 180, depth_m: 1.2, stock_count: 2600, status: 'healthy'   },
  { id: 'pond_4', farmer_id: 'farmer_2', farm_id: 'farm_2', name: 'Pond 1', species: 'tilapia',      area_m2: 300, depth_m: 1.5, stock_count: 5000, status: 'critical'  },
  { id: 'pond_5', farmer_id: 'farmer_2', farm_id: 'farm_2', name: 'Pond 2', species: 'catfish',      area_m2: 220, depth_m: 1.3, stock_count: 3100, status: 'attention' },
];

// One inspection: the shape the API returns and the shape that is indexed.
// `notes` is the free-text field Typesense searches; the readings are the
// optional water-quality numbers from the fish conversion.
export const inspections = [
  {
    id: 'insp_001',
    farmer_id: 'farmer_1',
    pond_id: 'pond_1',
    pond_name: 'Pond A',
    farm_name: 'Lakeview Fish Farm',
    species: 'tilapia',
    inspection_date: 1759000000,
    notes:
      'Fish showing early signs of fin rot on the tail. Ammonia reading elevated after heavy feeding. Recommend reducing feed by half and a 20% water exchange.',
    status: 'attention',
    mortality_count: 12,
    dissolved_oxygen: 3.1,
    water_temperature: 29.5,
    ph: 7.8,
    ammonia: 1.2,
  },
  {
    id: 'insp_002',
    farmer_id: 'farmer_1',
    pond_id: 'pond_2',
    pond_name: 'Pond B',
    farm_name: 'Lakeview Fish Farm',
    species: 'catfish',
    inspection_date: 1759100000,
    notes:
      'Low oxygen event overnight. Fish gasping at the surface at dawn. Aerator was off for four hours. Dissolved oxygen recovered to 5.2 by mid morning.',
    status: 'critical',
    mortality_count: 40,
    dissolved_oxygen: 2.4,
    water_temperature: 31.0,
    ph: 7.2,
    ammonia: 0.9,
  },
  {
    id: 'insp_003',
    farmer_id: 'farmer_1',
    pond_id: 'pond_3',
    pond_name: 'Pond C',
    farm_name: 'Lakeview Fish Farm',
    species: 'tilapia',
    inspection_date: 1759200000,
    notes:
      'Routine check. Water clear, light green colour, good plankton bloom. Fish feeding actively at the surface. No mortality. Continue current feeding schedule.',
    status: 'healthy',
    mortality_count: 0,
    dissolved_oxygen: 6.4,
    water_temperature: 27.8,
    ph: 7.6,
    ammonia: 0.2,
  },
  {
    id: 'insp_004',
    farmer_id: 'farmer_2',
    pond_id: 'pond_4',
    pond_name: 'Pond 1',
    farm_name: 'Riverside Aquaculture',
    species: 'tilapia',
    inspection_date: 1759250000,
    notes:
      'Ammonia spike detected. Water smells foul and has turned brownish. Partial water exchange done. Parasites visible on gills of two sampled fish.',
    status: 'critical',
    mortality_count: 25,
    dissolved_oxygen: 3.8,
    water_temperature: 30.2,
    ph: 8.1,
    ammonia: 2.4,
  },
  {
    id: 'insp_005',
    farmer_id: 'farmer_2',
    pond_id: 'pond_5',
    pond_name: 'Pond 2',
    farm_name: 'Riverside Aquaculture',
    species: 'catfish',
    inspection_date: 1759300000,
    notes:
      'Overfeeding observed last week left uneaten feed on the pond bottom. Water turbid. Reducing feed and monitoring ammonia daily.',
    status: 'attention',
    mortality_count: 5,
    dissolved_oxygen: 4.6,
    water_temperature: 28.9,
    ph: 7.4,
    ammonia: 0.7,
  },
  {
    id: 'insp_006',
    farmer_id: 'farmer_1',
    pond_id: 'pond_1',
    pond_name: 'Pond A',
    farm_name: 'Lakeview Fish Farm',
    species: 'tilapia',
    inspection_date: 1759350000,
    notes:
      'Follow up after the fin rot treatment. Lesions on the tail are healing and no new mortality since last visit. Water quality back within range. Tilapia feeding normally again.',
    status: 'healthy',
    mortality_count: 2,
    dissolved_oxygen: 5.9,
    water_temperature: 28.1,
    ph: 7.7,
    ammonia: 0.3,
  },
  {
    id: 'insp_007',
    farmer_id: 'farmer_1',
    pond_id: 'pond_2',
    pond_name: 'Pond B',
    farm_name: 'Lakeview Fish Farm',
    species: 'catfish',
    inspection_date: 1759400000,
    notes:
      'Aerator serviced and now running on a timer. Dissolved oxygen stable at 6.1 through the night. Some fish still showing stress stripes but feeding resumed.',
    status: 'attention',
    mortality_count: 8,
    dissolved_oxygen: 6.1,
    water_temperature: 29.0,
    ph: 7.3,
    ammonia: 0.5,
  },
  {
    id: 'insp_008',
    farmer_id: 'farmer_2',
    pond_id: 'pond_4',
    pond_name: 'Pond 1',
    farm_name: 'Riverside Aquaculture',
    species: 'tilapia',
    inspection_date: 1759450000,
    notes:
      'Water exchange and aeration improved conditions. Ammonia down to 0.6. Tilapia gills cleared of parasites after the salt bath. Mortality stopped.',
    status: 'healthy',
    mortality_count: 0,
    dissolved_oxygen: 5.5,
    water_temperature: 29.4,
    ph: 7.9,
    ammonia: 0.6,
  },
];

/// The public shape of an inspection (what Flutter receives).
export function publicInspection(i) {
  return { ...i };
}
