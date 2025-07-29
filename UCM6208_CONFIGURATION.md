# UCM6208 WSS Configuration Guide

## 🔧 **Current Configuration**

Your Flutter SIP client is now configured to connect to your UCM6208 using:

```dart
// In lib/controllers/simple_call_controller.dart
sipService.register(
  username: '003',
  password: 'tr123',
  domain: '172.16.26.2',
  wsUri: 'wss://172.16.26.2:8089/wss',  // ✅ Updated to WSS
  displayName: 'Flutter SIP Client',
);
```

## 🌐 **UCM6208 WebSocket Settings**

### **Required UCM6208 Configuration:**

1. **WebSocket Server Settings:**
   - **Protocol**: WSS (WebSocket Secure)
   - **IP Address**: 172.16.26.2
   - **Port**: 8089
   - **Path**: /wss
   - **Full URL**: `wss://172.16.26.2:8089/wss`

2. **SIP Extension Settings:**
   - **Extension**: 003
   - **Password**: tr123
   - **Domain**: 172.16.26.2

3. **Security Settings:**
   - **SSL Certificate**: Self-signed or valid certificate
   - **Allow Bad Certificate**: Enabled (for testing)

## 🔍 **UCM6208 Web Interface Configuration**

### **Step 1: Access UCM6208 Web Interface**
```
http://172.16.26.2
Username: admin
Password: (your admin password)
```

### **Step 2: Configure WebSocket Server**
1. Go to **System → WebSocket Server**
2. Set the following:
   - **Enable WebSocket Server**: ✅ Yes
   - **WebSocket Port**: 8089
   - **WebSocket Path**: /wss
   - **Enable SSL**: ✅ Yes
   - **SSL Certificate**: (your certificate)

### **Step 3: Configure SIP Extension**
1. Go to **PBX → Extensions**
2. Find extension **003** or create it:
   - **Extension**: 003
   - **Password**: tr123
   - **Display Name**: Flutter SIP Client
   - **WebRTC**: ✅ Enabled
   - **Transport**: WebSocket

### **Step 4: Configure Codecs**
1. Go to **PBX → Codec Settings**
2. Ensure these codecs are enabled:
   - ✅ **G711u** (PCMU)
   - ✅ **G711a** (PCMA)
   - ✅ **G722**
   - ❌ **G726-32** (disabled to avoid conflicts)
   - ✅ **G729**
   - ✅ **GSM**
   - ✅ **iLBC**

## 🚀 **Testing the Connection**

### **Step 1: Build and Run**
```bash
flutter build web
cd deployment
python start_server.py
```

### **Step 2: Access the Application**
```
http://localhost:8081
```

### **Step 3: Check Registration Status**
1. Open browser console (F12)
2. Look for these messages:
   ```
   📞 Auto-registering with SIP server...
   🚀 Starting SIP registration...
   📞 Username: 003
   📞 Domain: 172.16.26.2
   📞 WebSocket URL: wss://172.16.26.2:8089/wss
   ```

### **Step 4: Verify Connection**
- **Green Status**: ✅ Registered with SIP Server
- **Orange Status**: 🔄 Auto-registering...
- **Red Status**: ❌ Not Registered

## 🔧 **Troubleshooting**

### **Connection Issues:**

1. **"Connection Refused"**
   - Check if UCM6208 WebSocket server is running
   - Verify port 8089 is open
   - Check firewall settings

2. **"SSL Certificate Error"**
   - The app is configured with `allowBadCertificate = true`
   - If still failing, check UCM6208 SSL certificate

3. **"Registration Failed"**
   - Verify extension 003 exists
   - Check password is correct
   - Ensure WebRTC is enabled for the extension

### **Audio Issues:**

1. **One-Way Audio**
   - Check codec compatibility
   - Ensure G726-32 is disabled on UCM6208
   - Try different audio devices

2. **No Audio**
   - Check microphone permissions
   - Test microphone in browser
   - Verify WebRTC is working

### **WebSocket Debugging:**

Add this to browser console to test WebSocket connection:
```javascript
// Test WebSocket connection
const ws = new WebSocket('wss://172.16.26.2:8089/wss');
ws.onopen = () => console.log('✅ WebSocket connected');
ws.onerror = (e) => console.log('❌ WebSocket error:', e);
ws.onclose = () => console.log('📞 WebSocket closed');
```

## 📱 **Browser Requirements**

### **Supported Browsers:**
- ✅ **Chrome/Edge**: Full WebRTC support
- ✅ **Firefox**: Good WebRTC support
- ⚠️ **Safari**: Limited WebRTC support
- ❌ **Internet Explorer**: Not supported

### **HTTPS Requirement:**
- **Local Development**: HTTP works for testing
- **Production**: HTTPS required for WebRTC
- **WSS**: Always uses SSL/TLS

## 🔄 **Next Steps**

1. **Test Registration**: Verify the client connects to UCM6208
2. **Test Incoming Calls**: Make a call to extension 003
3. **Test Outgoing Calls**: Call another extension from the app
4. **Test Recording**: Verify call recording works
5. **Test Audio Quality**: Ensure two-way audio works

## 📞 **Support**

If you encounter issues:
1. Check browser console for error messages
2. Verify UCM6208 configuration
3. Test WebSocket connection manually
4. Check network connectivity between client and UCM6208

---

**✅ Configuration Complete!** Your Flutter SIP client is now configured to connect to your UCM6208 using WSS on port 8089. 