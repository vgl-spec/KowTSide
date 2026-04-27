const fs = require('fs');
const http = require('http');
const path = require('path');

const port = Number(process.env.PORT || process.argv[2] || 58100);
const host = process.env.HOST || '127.0.0.1';
const root = path.resolve(__dirname, '..', 'build', 'web');

const contentTypes = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
};

function resolveRequestPath(url) {
  const pathname = decodeURIComponent(String(url || '/').split('?')[0]);
  const requested = pathname === '/' ? '/index.html' : pathname;
  const candidate = path.resolve(root, '.' + requested);
  if (!candidate.startsWith(root)) {
    return null;
  }
  return candidate;
}

const server = http.createServer((req, res) => {
  let filePath = resolveRequestPath(req.url);
  if (!filePath) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  fs.stat(filePath, (statError, stat) => {
    if (statError || !stat.isFile()) {
      filePath = path.join(root, 'index.html');
    }

    fs.readFile(filePath, (readError, data) => {
      if (readError) {
        res.writeHead(404);
        res.end('Not found');
        return;
      }

      res.writeHead(200, {
        'Content-Type':
          contentTypes[path.extname(filePath).toLowerCase()] ||
          'application/octet-stream',
      });
      res.end(data);
    });
  });
});

server.listen(port, host, () => {
  console.log(`Serving KOW admin build at http://${host}:${port}`);
});
