#!/usr/bin/env node
/**
 * PDF Viewer Static File Server
 *
 * Serves workspace files and redirects root requests to the provenance
 * viewer at .lasco/provenance.html. Used by the "Start PDF Viewer Server"
 * VS Code task to power http://localhost:8017?box=<box_id> links.
 *
 * Zero dependencies — uses only Node.js built-ins.
 */

import { createServer } from 'http';
import { createReadStream, existsSync } from 'fs';
import { resolve, extname } from 'path';
import { URL } from 'url';

const PORT = 8017;
const LASCO_VIEWER = '/.lasco/provenance.html';

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js':   'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.pdf':  'application/pdf',
  '.css':  'text/css; charset=utf-8',
  '.png':  'image/png',
  '.jpg':  'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg':  'image/svg+xml',
};

const server = createServer((req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  const pathname = decodeURIComponent(url.pathname);

  // Root requests → redirect to provenance viewer, preserving query string
  if (pathname === '/' || pathname === '/index.html') {
    const location = url.search ? LASCO_VIEWER + url.search : LASCO_VIEWER;
    res.writeHead(302, { Location: location });
    res.end();
    return;
  }

  // Prevent path traversal
  const filePath = resolve(process.cwd(), '.' + pathname);
  if (!filePath.startsWith(process.cwd())) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  if (!existsSync(filePath)) {
    res.writeHead(404);
    res.end('Not found');
    return;
  }

  const ext = extname(filePath).toLowerCase();
  const contentType = MIME_TYPES[ext] || 'application/octet-stream';

  res.writeHead(200, { 'Content-Type': contentType });
  const stream = createReadStream(filePath);
  stream.on('error', (err) => {
    console.error(`[pdf-server] Read error for ${filePath}:`, err.message);
    if (!res.headersSent) {
      res.writeHead(500);
      res.end('Internal server error');
    } else {
      res.end();
    }
  });
  stream.pipe(res);
});

server.listen(PORT, () => {
  console.log(`[pdf-server] Serving workspace files on http://localhost:${PORT}`);
  console.log(`[pdf-server] Root redirects to ${LASCO_VIEWER}`);
});

const shutdown = () => {
  console.log('\n[pdf-server] Shutting down...');
  server.close(() => process.exit(0));
};

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
