import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readdir, readFile, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const output = path.join(projectRoot, 'build', 'web');
const baseHref = '/outer-edge-forge-candle-calculator/';
const flutter = process.env.OEF_FLUTTER_BIN || 'flutter';

const result = spawnSync(flutter, [
  'build', 'web', '--release', '--no-pub', '--no-wasm-dry-run',
  '--base-href', baseHref,
], { cwd: projectRoot, stdio: 'inherit' });
if (result.error) throw result.error;
if (result.status !== 0) process.exit(result.status ?? 1);

const indexPath = path.join(output, 'index.html');
const marker = '<!-- OEF_RELEASE_SERVICE_WORKER -->';
const index = await readFile(indexPath, 'utf8');
if (!index.includes(marker)) throw new Error('Service worker marker missing from index.html');
await writeFile(
  indexPath,
  index.replace(marker, '<script src="sw-register.js" defer></script>'),
);

// Flutter's legacy stub is not registered or used by this release.
await rm(path.join(output, 'flutter_service_worker.js'), { force: true });
await rm(path.join(output, 'sw.js'), { force: true });

async function listFiles(directory, prefix = '') {
  const entries = await readdir(directory, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    // Flutter's hidden build marker is not a runtime asset.
    if (entry.name.startsWith('.')) continue;
    const relative = path.posix.join(prefix, entry.name);
    if (entry.isDirectory()) {
      files.push(...await listFiles(path.join(directory, entry.name), relative));
    } else if (entry.isFile() &&
        !relative.endsWith('.symbols') &&
        !relative.endsWith('.map') &&
        relative !== 'assets/NOTICES') {
      files.push(relative);
    }
  }
  return files.sort();
}

const files = await listFiles(output);
const digest = createHash('sha256');
for (const file of files) {
  digest.update(file);
  digest.update('\0');
  digest.update(await readFile(path.join(output, file)));
}
const version = digest.digest('hex').slice(0, 20);
const template = await readFile(path.join(projectRoot, 'tools', 'sw-template.js'), 'utf8');
const worker = template
  .replace('__OEF_BUILD_VERSION__', version)
  .replace('__OEF_PRECACHE_FILES__', JSON.stringify(['./', ...files]));
await writeFile(path.join(output, 'sw.js'), worker);
console.log(`OEF offline release: ${files.length + 1} URLs cached, version ${version}`);
