// One-off: create the collection if needed and index every existing
// inspection. Safe to re-run; it upserts rather than duplicating.
import 'dotenv/config';
import { inspections } from './data.js';
import { createCollectionIfMissing, bulkIndex } from './typesense-service.js';

const created = await createCollectionIfMissing();
console.log(created.created ? 'Created collection.' : 'Collection already exists.');

const result = await bulkIndex(inspections);
const failed = result.filter((r) => !r.success);
console.log(`Indexed ${result.length - failed.length}/${result.length} inspections.`);
if (failed.length) {
  console.error('Failures:', failed.slice(0, 5));
  process.exit(1);
}
