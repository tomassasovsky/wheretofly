import { OmHttpBackend, OmFileReader, OmDataType, initWasm, LruBlockCache } from '@openmeteo/file-reader';

const url = process.argv[2];
await initWasm();
const backend = new OmHttpBackend({ url, eTagValidation: false, retries: 2 });
const cache = new LruBlockCache(64 * 1024, 128);
const reader = await OmFileReader.create(await backend.asCachedReader(cache));
const child = await reader.getChildByName('wind_gusts_10m');
console.log('dims', child.getDimensions(), 'chunks', child.getChunkDimensions(), 'name', child.getName());
const ranges = [{ start: 0, end: 100 }, { start: 0, end: 100 }];
const data = await child.read({ type: OmDataType.FloatArray, ranges });
console.log('values len', data.values.length, 'sample', data.values.slice(0, 5));
