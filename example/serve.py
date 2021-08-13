import sys

assert tuple(sys.version_info) >= (3, 8), 'http.server.ThreadingHTTPServer available in Python 3.8+, your Python version is: ' + sys.version

import http.server
import socketserver

PORT = 8080

Handler = http.server.SimpleHTTPRequestHandler

Handler.extensions_map = {
    '.manifest': 'text/cache-manifest',
    '.html': 'text/html',
    '.png': 'image/png',
    '.jpg': 'image/jpg',
    '.svg':	'image/svg+xml',
    '.css':	'text/css',
    '.js':	'application/x-javascript',
    '.wasm': 'application/wasm',
    '': 'application/octet-stream'
}

Server = http.server.ThreadingHTTPServer # socketserver.TCPServer
httpd = Server(("", PORT), Handler)

print("serving at port", PORT)
httpd.serve_forever()
