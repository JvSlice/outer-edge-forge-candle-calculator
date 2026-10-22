import { createReadStream } from 'node:fs';
import { stat } from 'node:fs/promises';
import { createServer } from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', 'build', 'web');
const base = '/outer-edge-forge-candle-calculator/';
const port = Number(process.env.OEF_PREVIEW_PORT || 8767);
const types = {
  '.bin': 'application/octet-stream',
  '.frag': 'application/octet-stream',
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.otf': 'font/otf',
  '.png': 'image/png',
  '.wasm': 'application/wasm',
};

createServer(async (request, response) => {
  let pathname;
  try {
    pathname = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);
  } catch {
    response.writeHead(400).end();
    return;
  }
  if (pathname === base.slice(0, -1)) {
    response.writeHead(301, { Location: base }).end();
    return;
  }
  if (!pathname.startsWith(base)) {
    response.writeHead(404).end();
    return;
  }
  const relative = pathname.slice(base.length) || 'index.html';
  const filename = path.resolve(root, relative);
  if (!filename.startsWith(root + path.sep)) {
    response.writeHead(403).end();
    return;
  }
  try {
    const info = await stat(filename);
    if (!info.isFile()) throw new Error('Not a file');
    response.writeHead(200, {
      'Content-Type': types[path.extname(filename)] || 'application/octet-stream',
      'Content-Length': info.size,
      'Cache-Control': 'no-cache',
    });
    createReadStream(filename).pipe(response);
  } catch {
    response.writeHead(404).end();
  }
}).listen(port, '127.0.0.1', () => {
  console.log(`OEF release preview: http://127.0.0.1:${port}${base}`);
});
