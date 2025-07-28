# Quick Installation Guide

## 🚀 Quick Start (Testing)

1. **Download** the deployment folder to your computer
2. **Open Command Prompt** in the deployment folder
3. **Run**: `python start_server.py`
4. **Open browser** and go to: `http://localhost:8080`

## 🏢 Production Deployment

### Option 1: Apache Web Server
1. Copy all files from `web` folder to `/var/www/html/`
2. Configure Apache with HTTPS
3. Access via your domain name

### Option 2: Nginx Web Server
1. Copy all files from `web` folder to `/usr/share/nginx/html/`
2. Configure Nginx with HTTPS
3. Access via your domain name

### Option 3: IIS (Windows)
1. Copy all files from `web` folder to `C:\inetpub\wwwroot\`
2. Configure IIS with HTTPS
3. Access via your domain name

## ⚙️ Configuration

**IMPORTANT**: Before using, update the SIP settings in the source code:

1. Open `lib/controllers/simple_call_controller.dart`
2. Update the `register()` method:

```dart
void register() {
  sipService.register(
    username: 'YOUR_EXTENSION',      // Your SIP extension
    password: 'YOUR_PASSWORD',       // Your SIP password  
    domain: 'YOUR_UCM_IP',          // Your UCM6208 IP
    wsUri: 'ws://YOUR_UCM_IP:8088/ws', // WebSocket URL
  );
}
```

3. Rebuild: `flutter build web --release`
4. Deploy the new `build/web` files

## 🔧 UCM6208 Setup

1. **Enable WebSocket** in UCM6208 admin panel
2. **Create SIP Extension** for the web client
3. **Open Port 8088** in firewall
4. **Test WebSocket** connection

## 📞 Support

For technical support, contact your development team.

---

**Version**: 1.0.0  
**Built**: July 2025 