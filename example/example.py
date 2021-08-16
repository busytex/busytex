import sys
import argparse
assert tuple(sys.version_info) >= (3, 8), 'http.server.ThreadingHTTPServer available in Python 3.8+, your Python version is: ' + sys.version

import http.server
import socketserver

parser = argparse.ArgumentParser()
parser.add_argument('--port', type = int, default = 8080)
parser.add_argument('--server', default = 'ThreadingHTTPServer', choices = ['ThreadingHTTPServer', 'TCPServer'])
args = parser.parse_args()

ext_map = {
    '.manifest': 'text/cache-manifest',
    '.html': 'text/html',
    '.png': 'image/png',
    '.jpg': 'image/jpg',
    '.svg': 'image/svg+xml',
    '.css': 'text/css',
    '.js': 'application/x-javascript',
    '.wasm': 'application/wasm',
    '': 'application/octet-stream'
}

Handler = http.server.SimpleHTTPRequestHandler
Handler.extensions_map = ext_map
httpd = (http.server.ThreadingHTTPServer if args.server == 'ThreadingHTTPServer' else socketserver.TCPServer)(('', args.port), Handler)

print(f'serving at http://localhost:{args.port}')
httpd.serve_forever()
