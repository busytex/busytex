# -*- coding: utf-8 -*-
#test on python 3.4 ,python of lower version  has different module organization.
import http.server
import socketserver

PORT = 8080

Handler = http.server.SimpleHTTPRequestHandler

Handler.extensions_map={
        '.manifest': 'text/cache-manifest',
	'.html': 'text/html',
        '.png': 'image/png',
	'.jpg': 'image/jpg',
	'.svg':	'image/svg+xml',
	'.css':	'text/css',
	'.js':	'application/x-javascript',
	'.wasm': 'application/wasm',
	'': 'application/octet-stream', # Default
    }

Server = http.server.ThreadingHTTPServer
#Server = socketserver.TCPServer
httpd = Server(("", PORT), Handler)

print("serving at port", PORT)
httpd.serve_forever()
