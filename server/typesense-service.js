// Server-side Typesense integration.
//
// Two rules this file exists to enforce:
//   1. The admin key never leaves this process. Flutter never sees it.
//   2. Flutter never gets the raw search-only parent key either, because that
//      key can search every farmer's inspections. It gets a scoped key whose
//      embedded filter_by can only ever match one farmer.
import Typesense from 'typesense';

const {
  TYPESENSE_HOST = 'localhost',
  TYPESENSE_PORT = '8108',
  TYPESENSE_PROTOCOL = 'http',
  TYPESENSE_COLLECTION = 'inspections',
} = process.env;

export const COLLECTION = TYPESENSE_COLLECTION;

// Full access. Only ever used from this server.
const adminClient = new Typesense.Client({
  nodes: [
    {
      host: TYPESENSE_HOST,
      port: Number(TYPESENSE_PORT),
      protocol: TYPESENSE_PROTOCOL,
    },
  ],
  apiKey: process.env.TYPESENSE_ADMIN_KEY ?? '',
  connectionTimeoutSeconds: 5,
});

// The collection schema. Field names match exactly what is in data.js, so
// nothing is indexed that the app does not actually have.
export const collectionSchema = {
  name: COLLECTION,
  fields: [
    { name: 'id', type: 'string' },
    { name: 'farmer_id', type: 'string', facet: true },
    { name: 'pond_id', type: 'string', facet: true },
    { name: 'pond_name', type: 'string' },
    { name: 'farm_name', type: 'string', optional: true },
    { name: 'species', type: 'string', facet: true, optional: true },
    { name: 'inspection_date', type: 'int64' },
    { name: 'notes', type: 'string' },
    { name: 'status', type: 'string', facet: true, optional: true },
    { name: 'mortality_count', type: 'int32', optional: true },
    { name: 'dissolved_oxygen', type: 'float', optional: true },
    { name: 'water_temperature', type: 'float', optional: true },
    { name: 'ph', type: 'float', optional: true },
    { name: 'ammonia', type: 'float', optional: true },
  ],
  default_sorting_field: 'inspection_date',
};

export async function createCollectionIfMissing() {
  try {
    await adminClient.collections(COLLECTION).retrieve();
    return { created: false };
  } catch (err) {
    if (err?.httpStatus !== 404) throw err;
    await adminClient.collections().create(collectionSchema);
    return { created: true };
  }
}

/// Convert an inspection into the exact document shape the schema expects.
/// Undefined/null optionals are dropped rather than sent as null, because
/// Typesense rejects null for a typed field.
function toDocument(inspection) {
  const doc = {
    id: String(inspection.id),
    farmer_id: String(inspection.farmer_id),
    pond_id: String(inspection.pond_id),
    pond_name: inspection.pond_name ?? '',
    inspection_date: Number(inspection.inspection_date),
    notes: inspection.notes ?? '',
  };
  const maybe = [
    'farm_name',
    'species',
    'status',
    'mortality_count',
    'dissolved_oxygen',
    'water_temperature',
    'ph',
    'ammonia',
  ];
  for (const key of maybe) {
    if (inspection[key] !== undefined && inspection[key] !== null) {
      doc[key] = inspection[key];
    }
  }
  return doc;
}

export const indexInspection = (inspection) =>
  adminClient
    .collections(COLLECTION)
    .documents()
    .upsert(toDocument(inspection));

export const deleteInspection = (id) =>
  adminClient.collections(COLLECTION).documents(String(id)).delete();

/// Bulk import, used by seed.js and by any "reindex everything" command.
export const bulkIndex = (inspections) =>
  adminClient
    .collections(COLLECTION)
    .documents()
    .import(inspections.map(toDocument), { action: 'upsert' });

/// Generate the short-lived, search-only, farmer-scoped key.
///
/// The parent key must have ONLY documents:search on this collection. The
/// embedded filter_by is applied by Typesense itself, so the app cannot
/// override it and cannot widen it.
export function scopedSearchKey({ farmerId, ttlSeconds = 86400 }) {
  const searchKey = process.env.TYPESENSE_SEARCH_KEY;
  if (!searchKey) {
    throw new Error('TYPESENSE_SEARCH_KEY is not set on the server.');
  }
  return adminClient
    .keys()
    .generateScopedSearchKey(searchKey, {
      filter_by: `farmer_id:=${farmerId}`,
      expires_at: Math.floor(Date.now() / 1000) + ttlSeconds,
    });
}

/// What the Flutter app needs to make a search call: where to go and with
/// which key. No secret beyond the scoped key leaves the server.
export function searchClientConfig({ farmerId, ttlSeconds }) {
  return {
    key: scopedSearchKey({ farmerId, ttlSeconds }),
    host: TYPESENSE_HOST,
    port: Number(TYPESENSE_PORT),
    protocol: TYPESENSE_PROTOCOL,
    collection: COLLECTION,
    expiresAt: Math.floor(Date.now() / 1000) + ttlSeconds,
  };
}

export { adminClient };
