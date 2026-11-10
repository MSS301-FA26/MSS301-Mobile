"""Serve only a PNG/invalid HTML fixture on loopback for device avatar QA."""
import base64
from http.server import BaseHTTPRequestHandler, HTTPServer

PNG = base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=')


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/plan02.png':
            status, mime, body = 200, 'image/png', PNG
        elif self.path == '/invalid.html':
            status, mime, body = 200, 'text/html', b'<html>QA: not an image</html>'
        else:
            status, mime, body = 404, 'text/plain', b'Not found'
        self.send_response(status)
        self.send_header('Content-Type', mime)
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *_):
        pass


print('Avatar QA fixtures on loopback port 18081', flush=True)
HTTPServer(('127.0.0.1', 18081), Handler).serve_forever()
