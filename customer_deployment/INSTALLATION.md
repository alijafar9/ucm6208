# Quick Installation Guide

## 🚀 **Step-by-Step Installation**

### **1. Test Locally (Recommended First)**

1. **Download** this package to your computer
2. **Open Command Prompt** in this folder
3. **Run**: `python start_server.py`
4. **Open browser** and go to: `http://localhost:8080`
5. **Test microphone** using the built-in test feature

### **2. Production Deployment**

#### **Apache Web Server**
```bash
# Copy files to web root
cp -r web/* /var/www/html/

# Configure HTTPS (required for microphone access)
# Add SSL certificate and configure Apache
```

#### **Nginx Web Server**
```bash
# Copy files to web root
cp -r web/* /usr/share/nginx/html/

# Configure HTTPS and Nginx settings
```

#### **IIS (Windows)**
```cmd
# Copy files to web root
xcopy web\* C:\inetpub\wwwroot\ /E /I

# Configure HTTPS in IIS Manager
```

## ⚙️ **Configuration**

### **Update SIP Settings**
**CRITICAL**: Before using, update the SIP configuration:

1. **Open**: `lib/controllers/simple_call_controller.dart`
2. **Update the register() method**:
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
3. **Rebuild**: `flutter build web --release`
4. **Deploy** the new files

### **UCM6208 Setup**
1. **Enable WebSocket** in UCM6208 admin panel
2. **Create SIP Extension** for the web client
3. **Open Port 8088** in firewall
4. **Test WebSocket** connection

## 🎤 **Microphone Setup**

### **Browser Permissions**
- **Allow microphone access** when prompted
- **Check browser settings** (lock/shield icon in address bar)
- **Use HTTPS** in production (required for microphone access)

### **System Settings**
- **Windows**: Settings → Privacy & Security → Microphone
- **macOS**: System Preferences → Security & Privacy → Microphone
- **Linux**: Check PulseAudio settings

## 📞 **Testing**

### **Test Microphone**
1. **Open the application**
2. **Click "Test Microphone"** in the blue section
3. **Allow permission** when prompted
4. **Verify status** shows "✅ Microphone permission granted!"

### **Test SIP Registration**
1. **Check console** for "SIP helper started successfully"
2. **Verify registration** status
3. **Test incoming calls** from another extension

### **Test Calls**
1. **Make outgoing call** to another extension
2. **Receive incoming call** from another phone
3. **Test call controls** (answer, reject, hang up, mute)

## 🔧 **Troubleshooting**

### **Common Issues**

**Microphone Not Working**
- Check browser permissions
- Use HTTPS in production
- Test with different browser
- Check system microphone settings

**SIP Registration Fails**
- Verify UCM6208 IP address
- Check username/password
- Ensure WebSocket port is open
- Check firewall settings

**No Incoming Call UI**
- Check browser console for errors
- Verify SIP registration is successful
- Ensure WebSocket connection is established

**WebSocket Connection Issues**
- Check firewall settings
- Verify UCM6208 WebSocket is enabled
- Try different browser
- Check network connectivity

## 📞 **Support**

For technical support or customization requests, contact your development team.

---

**Version**: 1.0.0  
**Built**: July 2025 