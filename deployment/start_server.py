#!/usr/bin/env python3
"""
Simple HTTP Server for Flutter Web SIP Client
Run this script to serve the application locally for testing.
"""

import http.server
import socketserver
import os
import sys
from pathlib import Path

# Configuration
PORT = 8081
DIRECTORY = "web"

def main():
    # Change to the web directory
    web_dir = Path(__file__).parent / DIRECTORY
    if not web_dir.exists():
        print(f"Error: {web_dir} directory not found!")
        print("Make sure you're running this script from the deployment folder.")
        sys.exit(1)
    
    os.chdir(web_dir)
    
    # Create server
    Handler = http.server.SimpleHTTPRequestHandler
    Handler.extensions_map.update({
        '.js': 'application/javascript',
        '.html': 'text/html',
        '.css': 'text/css',
        '.json': 'application/json',
        '.wasm': 'application/wasm',
    })
    
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print(f"🚀 Server started at http://localhost:{PORT}")
        print(f"📁 Serving files from: {web_dir.absolute()}")
        print("📱 Open your browser and navigate to the URL above")
        print("⚠️  Note: For production use, use a proper web server like Apache or Nginx")
        print("🔒 For microphone access, HTTPS is required in production")
        print("\nPress Ctrl+C to stop the server")
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n🛑 Server stopped")

if __name__ == "__main__":
    main() 