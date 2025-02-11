const http = require('http');
const fs = require('fs');
const path = require('path');
const { argv } = require('process');

const args = require('minimist')(argv.slice(2), {
    default: { port: 8080, server: 'threaded' },
    alias: { p: 'port', s: 'server' }
});

const MIME_TYPES = {
    '.manifest': 'text/cache-manifest',
    '.html': 'text/html',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.svg': 'image/svg+xml',
    '.css': 'text/css',
    '.js': 'application/javascript',
    '.wasm': 'application/wasm',
    'default': 'application/octet-stream'
};

const requestHandler = (req, res) => {
    let filePath = path.join(__dirname, req.url);
    if (fs.statSync(filePath).isDirectory()) {
        filePath = path.join(filePath, '../example/example.html'); // Serve example.html if directory
    }

    fs.readFile(filePath, (err, data) => {
        if (err) {
            res.writeHead(404, { 'Content-Type': 'text/plain' });
            res.end('404 Not Found');
            return;
        }

        const ext = path.extname(filePath);
        res.writeHead(200, { 'Content-Type': MIME_TYPES[ext] || MIME_TYPES['default'] });
        res.end(data);
    });
};

const server = http.createServer(requestHandler);
server.listen(args.port, () => {
    console.log(`Serving at http://localhost:${args.port}`);
});