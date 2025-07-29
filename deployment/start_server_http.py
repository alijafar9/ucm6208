import http.server
import socketserver
import os
import sys

# Configuration
PORT = 8081
DIRECTORY = "web"

def main():
    # Change to the script's directory
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    
    # Check if web directory exists
    if not os.path.exists(DIRECTORY):
        print(f"❌ Error: '{DIRECTORY}' directory not found!")
        print(f"📁 Current directory: {os.getcwd()}")
        print(f"📁 Available files: {os.listdir('.')}")
        sys.exit(1)
    
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
        # HTTP Server
        httpd = socketserver.TCPServer(("", PORT), handler)
        print(f"🌐 HTTP Server running at http://localhost:{PORT}")
        print(f"🌐 HTTP Server running at http://172.16.26.2:{PORT}")
        print("⚠️ Warning: WebRTC features may not work without HTTPS!")
        print("💡 For full functionality, use start_server.py with HTTPS")
        
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