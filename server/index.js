// Mock aquaculture API for the DroidCon hackathon build.
//
// There is no login in this build by design: the app picks a demo farmer and
// sends their id as `X-Farmer-Id`. In a real backend that header would be
// replaced by the authenticated user from the token, and nothing else in this
// file would change.
import 'dotenv/config';
import express from 'express';
import cors from 'cors';

import { farmers, farms, ponds, inspections } from './data.js';
import {
  createCollectionIfMissing,
  indexInspection,
  deleteInspection,
  searchClientConfig,
  bulkIndex,
} from './typesense-service.js';

const app = express();
app.use(cors());
app.use(express.json());

const PORT = Number(process.env.PORT ?? 8080);
const TTL = Number(process.env.SEARCH_KEY_TTL_SECONDS ?? 86400);

/// Resolve the acting farmer. This is the ONLY place identity is decided, so
/// it is the only thing a real auth layer would need to replace.
function currentFarmer(req, res) {
  const id = req.header('X-Farmer-Id') ?? req.query.farmer_id;
  const farmer = farmers.find((f) => f.id === id);
  if (!farmer) {
    res.status(401).json({
      message: 'Pick a demo farmer first (send the X-Farmer-Id header).',
      farmers: farmers.map((f) => ({ id: f.id, name: f.name })),
    });
    return null;
  }
  return farmer;
}

const ok = (res, data) => res.json({ success: true, data });

// ---- Demo farmers (stands in for login) ----

app.get('/api/farmers', (_req, res) => ok(res, farmers));

// ---- Farms & ponds ----

app.get('/api/farms', (req, res) => {
  const farmer = currentFarmer(req, res);
  if (!farmer) return;
  ok(res, farms.filter((f) => f.farmer_id === farmer.id));
});

app.get('/api/ponds', (req, res) => {
  const farmer = currentFarmer(req, res);
  if (!farmer) return;
  const farmId = req.query.farm_id;
  ok(
    res,
    ponds.filter(
      (p) => p.farmer_id === farmer.id && (!farmId || p.farm_id === farmId),
    ),
  );
});

// ---- Inspections ----

app.get('/api/inspections', (req, res) => {
  const farmer = currentFarmer(req, res);
  if (!farmer) return;
  const pondId = req.query.pond_id;
  const rows = inspections
    .filter((i) => i.farmer_id === farmer.id && (!pondId || i.pond_id === pondId))
    .sort((a, b) => b.inspection_date - a.inspection_date);
  ok(res, rows);
});

app.post('/api/inspections', async (req, res) => {
  const farmer = currentFarmer(req, res);
  if (!farmer) return;

  const pond = ponds.find((p) => p.id === req.body.pond_id);
  if (!pond || pond.farmer_id !== farmer.id) {
    return res.status(422).json({ message: 'Unknown pond for this farmer.' });
  }

  const inspection = {
    id: `insp_${Date.now()}`,
    farmer_id: farmer.id,
    pond_id: pond.id,
    pond_name: pond.name,
    farm_name: farms.find((f) => f.id === pond.farm_id)?.name,
    species: req.body.species ?? pond.species,
    inspection_date: req.body.inspection_date ?? Math.floor(Date.now() / 1000),
    notes: req.body.notes ?? '',
    status: req.body.status,
    mortality_count: req.body.mortality_count,
    dissolved_oxygen: req.body.dissolved_oxygen,
    water_temperature: req.body.water_temperature,
    ph: req.body.ph,
    ammonia: req.body.ammonia,
  };

  // The database is the source of truth; Typesense is the search copy.
  inspections.push(inspection);

  // Indexing happens here, on the server, and a search failure must never
  // fail the write. The app falls back to local filtering if the index lags.
  try {
    await indexInspection(inspection);
  } catch (err) {
    console.warn('Typesense index failed (write kept):', err.message);
  }

  res.status(201).json({ success: true, data: inspection });
});

app.delete('/api/inspections/:id', async (req, res) => {
  const farmer = currentFarmer(req, res);
  if (!farmer) return;
  const idx = inspections.findIndex(
    (i) => i.id === req.params.id && i.farmer_id === farmer.id,
  );
  if (idx === -1) return res.status(404).json({ message: 'Not found.' });
  inspections.splice(idx, 1);
  try {
    await deleteInspection(req.params.id);
  } catch (err) {
    console.warn('Typesense delete failed (row already gone):', err.message);
  }
  res.json({ success: true });
});

// ---- The Typesense search key endpoint ----

app.get('/api/search-key', (req, res) => {
  const farmer = currentFarmer(req, res);
  if (!farmer) return;
  try {
    ok(res, searchClientConfig({ farmerId: farmer.id, ttlSeconds: TTL }));
  } catch (err) {
    console.error('search-key failed:', err.message);
    res.status(503).json({ message: 'Search is not configured on the server.' });
  }
});

// ---- Admin / demo helpers ----

app.post('/api/admin/seed', async (_req, res) => {
  try {
    const created = await createCollectionIfMissing();
    const result = await bulkIndex(inspections);
    const failures = result.filter((r) => !r.success);
    res.json({
      success: true,
      collectionCreated: created.created,
      indexed: result.length - failures.length,
      failed: failures.length,
      failures: failures.slice(0, 5),
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

app.get('/health', (_req, res) => res.json({ ok: true }));

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Aquafarm API on http://localhost:${PORT}`);
});
