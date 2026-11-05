#!/usr/bin/env python3
"""Serve the Puzzle Parlour on this computer and your Wi-Fi, so you can play on your phone.

Usage: python serve.py [--port 8080] [--host 0.0.0.0] [--no-browser] [--verbose]
Prints a local link, a link for other devices on the same network, and (if the
optional `qrcode` package is installed) a QR code to scan with your phone.
"""
import argparse
import functools
import http.server
import os
import socket
import sys
import threading
import webbrowser

ROOT = os.path.dirname(os.path.abspath(__file__))


class Handler(http.server.SimpleHTTPRequestHandler):
    verbose = False

    def send_head(self):
        # never serve dotfiles/dot-folders such as .venv or .git
        parts = self.path.split('?', 1)[0].split('/')
        if any(p.startswith('.') and p not in ('', '.') for p in parts):
            self.send_error(404)
            return None
        return super().send_head()

    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()

    def log_message(self, fmt, *args):
        if self.verbose:
            super().log_message(fmt, *args)


def lan_address():
    """The address other devices on your network can reach (no packets are sent)."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('10.254.254.254', 1))
        return s.getsockname()[0]
    except OSError:
        return None
    finally:
        s.close()


def print_qr(url):
    try:
        import qrcode
    except ImportError:
        return
    qr = qrcode.QRCode(border=1)
    qr.add_data(url)
    qr.make(fit=True)
    print()
    qr.print_ascii(invert=True)


def main():
    ap = argparse.ArgumentParser(description='Serve the Puzzle Parlour games locally.')
    ap.add_argument('--port', type=int, default=int(os.environ.get('PORT', 8080)))
    ap.add_argument('--host', default='0.0.0.0', help='0.0.0.0 = reachable from your phone; 127.0.0.1 = this computer only')
    ap.add_argument('--no-browser', action='store_true', help="don't open a browser tab")
    ap.add_argument('--verbose', action='store_true', help='log every request')
    args = ap.parse_args()

    Handler.verbose = args.verbose
    handler = functools.partial(Handler, directory=ROOT)
    httpd = None
    for port in range(args.port, args.port + 20):
        try:
            httpd = http.server.ThreadingHTTPServer((args.host, port), handler)
            break
        except OSError:
            continue
    if httpd is None:
        sys.exit('Could not find a free port from %d to %d.' % (args.port, args.port + 19))
    port = httpd.server_address[1]

    local = 'http://localhost:%d/' % port
    print('\n  Puzzle Parlour is being served from', ROOT)
    print('  On this computer:  ', local)
    lan = lan_address() if args.host == '0.0.0.0' else None
    if lan:
        lan_url = 'http://%s:%d/' % (lan, port)
        print('  On your phone:     ', lan_url, '(same Wi-Fi)')
        print_qr(lan_url)
    print('\n  Press Ctrl+C to stop.\n')

    if not args.no_browser:
        threading.Timer(0.6, webbrowser.open, [local]).start()
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print('\n  Stopped.')
    finally:
        httpd.server_close()


if __name__ == '__main__':
    main()
