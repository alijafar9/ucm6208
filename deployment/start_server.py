#!/usr/bin/env python3
"""
Simple HTTP Server for Flutter Web SIP Client
Run this script to serve the application locally for testing.
"""

import http.server
import socketserver
import ssl
import os
import sys
from pathlib import Path

# Configuration
PORT = 8081
DIRECTORY = "web"
CERT_FILE = "localhost.crt"
KEY_FILE = "localhost.key"

def create_self_signed_cert():
    """Create a self-signed certificate for local development"""
    if not os.path.exists(CERT_FILE) or not os.path.exists(KEY_FILE):
        print("🔐 Creating self-signed certificate for HTTPS...")
        try:
            import subprocess
            # Create certificate using OpenSSL
            subprocess.run([
                'openssl', 'req', '-x509', '-newkey', 'rsa:4096', 
                '-keyout', KEY_FILE, '-out', CERT_FILE, '-days', '365', '-nodes',
                '-subj', '/C=US/ST=State/L=City/O=Organization/CN=localhost'
            ], check=True)
            print("✅ Self-signed certificate created successfully")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("⚠️ OpenSSL not found. Using HTTP only.")
            print("💡 To enable HTTPS, install OpenSSL and run this script again.")
            return False
    return True

def main():
    # Change to the script's directory
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    
    # Check if web directory exists
    if not os.path.exists(DIRECTORY):
        print(f"❌ Error: '{DIRECTORY}' directory not found!")
        print(f"📁 Current directory: {os.getcwd()}")
        print(f"📁 Available files: {os.listdir('.')}")
        sys.exit(1)
    
    # Try to create HTTPS certificate
    https_available = create_self_signed_cert()
    
    # Set up the server
    handler = http.server.SimpleHTTPRequestHandler
    handler.extensions_map.update({
        '.js': 'application/javascript',
        '.html': 'text/html',
        '.css': 'text/css',
        '.json': 'application/json',
        '.wasm': 'application/wasm',
    })
    
    try:
        if https_available and os.path.exists(CERT_FILE) and os.path.exists(KEY_FILE):
            # HTTPS Server
            httpd = socketserver.TCPServer(("", PORT), handler)
            httpd.socket = ssl.wrap_socket(
                httpd.socket,
                certfile=CERT_FILE,
                keyfile=KEY_FILE,
                server_side=True
            )
            print(f"🔒 HTTPS Server running at https://localhost:{PORT}")
            print(f"🔒 HTTPS Server running at https://172.16.26.2:{PORT}")
            print("⚠️ Note: You'll see a security warning. Click 'Advanced' and 'Proceed' to continue.")
        else:
            # HTTP Server (fallback)
            httpd = socketserver.TCPServer(("", PORT), handler)
            print(f"🌐 HTTP Server running at http://localhost:{PORT}")
            print(f"🌐 HTTP Server running at http://172.16.26.2:{PORT}")
            print("⚠️ Warning: WebRTC features may not work without HTTPS!")
        
        print(f"📁 Serving files from: {os.path.abspath(DIRECTORY)}")
        print("🛑 Press Ctrl+C to stop the server")
        print("-" * 50)
        
        httpd.serve_forever()
        
    except OSError as e:
        if e.errno == 10048:  # Port already in use
            print(f"❌ Error: Port {PORT} is already in use!")
            print("💡 Try stopping other servers or change the PORT in the script.")
        else:
            print(f"❌ Error starting server: {e}")
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
    except Exception as e:
        print(f"❌ Unexpected error: {e}")

if __name__ == "__main__":
    main() 