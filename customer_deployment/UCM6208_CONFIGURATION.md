# UCM6208 Configuration Guide

## 🔧 **Step-by-Step UCM6208 Setup**

### **Prerequisites**
- UCM6208 device with admin access
- Network connectivity to UCM6208
- Web browser (Chrome recommended)
- SIP extension credentials

---

## 📋 **Step 1: Access UCM6208 Admin Panel**

### **1.1 Find UCM6208 IP Address**
1. **Check your network** for UCM6208 device
2. **Common IP addresses**:
   - `192.168.1.100`
   - `192.168.2.100`
   - `172.16.26.2` (your current setup)
3. **Use network scanner** or check router DHCP table

### **1.2 Access Web Interface**
1. **Open web browser** (Chrome recommended)
2. **Navigate to**: `http://YOUR_UCM6208_IP`
3. **Login** with admin credentials
4. **Default credentials** (if not changed):
   - Username: `admin`
   - Password: `admin`

---

## ⚙️ **Step 2: Enable WebSocket Support**

### **2.1 Navigate to WebSocket Settings**
1. **Login** to UCM6208 admin panel
2. **Go to**: `System` → `WebSocket Settings`
3. **Or look for**: `Advanced` → `WebSocket`

### **2.2 Configure WebSocket**
1. **Enable WebSocket**: Set to `Yes` or `Enabled`
2. **WebSocket Port**: Set to `8088` (default)
3. **WebSocket URL**: `ws://YOUR_UCM6208_IP:8088/ws`
4. **Save settings**

### **2.3 Verify WebSocket Status**
1. **Check WebSocket status** shows "Enabled"
2. **Note the port number** (usually 8088)
3. **Test connection** if available

---

## 📞 **Step 3: Create SIP Extension**

### **3.1 Navigate to Extensions**
1. **Go to**: `Extensions` → `SIP Extensions`
2. **Or**: `PBX` → `Extensions`

### **3.2 Add New Extension**
1. **Click**: `Add Extension` or `+`
2. **Extension Number**: Choose available number (e.g., `002`)
3. **Extension Name**: Give it a name (e.g., `Web Client`)
4. **Password**: Set a secure password (e.g., `tr123`)

### **3.3 Configure Extension Settings**
```
Extension Settings:
├── Extension Number: 002
├── Extension Name: Web Client
├── Password: tr123
├── SIP Port: 5060 (default)
├── Registration: Enabled
├── WebSocket: Enabled
└── NAT: Enabled (if behind router)
```

### **3.4 Advanced Settings**
1. **Codec Priority**: Set to `G711u, G711a, G729`
2. **DTMF Mode**: Set to `RFC2833`
3. **Registration Expiry**: `120` seconds
4. **Max Calls**: `1` (for web client)

---

## 🔒 **Step 4: Configure Firewall**

### **4.1 Open Required Ports**
**On UCM6208 Firewall:**
- **Port 8088**: WebSocket (TCP)
- **Port 5060**: SIP (UDP/TCP)
- **Port 10000-20000**: RTP Media (UDP)

### **4.2 Network Firewall (if applicable)**
**If UCM6208 is behind router/firewall:**
1. **Forward port 8088** to UCM6208 IP
2. **Forward port 5060** to UCM6208 IP
3. **Forward RTP range** (10000-20000) to UCM6208 IP

### **4.3 Test Port Accessibility**
```bash
# Test WebSocket port
telnet YOUR_UCM6208_IP 8088

# Test SIP port
telnet YOUR_UCM6208_IP 5060
```

---

## 🌐 **Step 5: Update SIP Client Configuration**

### **5.1 Update SIP Credentials**
1. **Open**: `lib/controllers/simple_call_controller.dart`
2. **Find the register() method**
3. **Update with your settings**:

```dart
void register() {
  sipService.register(
    username: '002',                    // Your extension number
    password: 'tr123',                  // Your extension password
    domain: '172.16.26.2',             // Your UCM6208 IP
    wsUri: 'ws://172.16.26.2:8088/ws', // WebSocket URL
  );
}
```

### **5.2 Rebuild Application**
```bash
# Navigate to project directory
cd /path/to/your/project

# Build production version
flutter build web --release

# Copy new files to web server
cp -r build/web/* /path/to/web/server/
```

---

## 🧪 **Step 6: Testing Configuration**

### **6.1 Test WebSocket Connection**
1. **Open browser console** (F12)
2. **Check for WebSocket connection** messages
3. **Look for**: "WebSocket connected" or similar

### **6.2 Test SIP Registration**
1. **Open application** in browser
2. **Check console** for registration messages
3. **Look for**: "SIP helper started successfully"
4. **Verify**: "Registration state changed: registered"

### **6.3 Test Incoming Calls**
1. **Call extension 002** from another phone
2. **Verify beautiful call UI** appears
3. **Test answer/reject** buttons
4. **Check caller information** display

### **6.4 Test Outgoing Calls**
1. **Enter another extension** in the app
2. **Click "Call"** button
3. **Verify call connects**
4. **Test call controls** (hang up, mute)

---

## 🔍 **Step 7: Troubleshooting**

### **7.1 WebSocket Connection Issues**
**Symptoms**: "WebSocket connection failed"
**Solutions**:
1. **Check UCM6208 WebSocket** is enabled
2. **Verify port 8088** is open
3. **Check firewall** settings
4. **Try different browser**

### **7.2 SIP Registration Issues**
**Symptoms**: "Registration failed" or "401 Unauthorized"
**Solutions**:
1. **Verify extension credentials** (username/password)
2. **Check extension** is enabled in UCM6208
3. **Verify SIP port** (5060) is accessible
4. **Check registration expiry** settings

### **7.3 Microphone Issues**
**Symptoms**: "Microphone permission denied"
**Solutions**:
1. **Allow microphone** in browser settings
2. **Use HTTPS** in production
3. **Check system microphone** settings
4. **Try different browser**

### **7.4 No Incoming Call UI**
**Symptoms**: Call rings but no UI appears
**Solutions**:
1. **Check browser console** for errors
2. **Verify SIP registration** is successful
3. **Ensure WebSocket** connection is established
4. **Test microphone permissions**

---

## 📊 **Step 8: Monitoring & Maintenance**

### **8.1 Monitor Registration Status**
1. **Check UCM6208 logs** for registration events
2. **Monitor WebSocket** connection status
3. **Verify extension** is always registered

### **8.2 Regular Maintenance**
1. **Update UCM6208 firmware** regularly
2. **Monitor system logs** for errors
3. **Test functionality** after updates
4. **Backup configuration** settings

### **8.3 Security Considerations**
1. **Use strong passwords** for extensions
2. **Enable HTTPS** in production
3. **Restrict access** to admin panel
4. **Monitor access logs**

---

## 📞 **Step 9: User Training**

### **9.1 Basic Usage**
1. **Opening the application**
2. **Testing microphone** permissions
3. **Making outgoing calls**
4. **Answering incoming calls**

### **9.2 Call Controls**
1. **Answer/Reject** incoming calls
2. **Hang up** active calls
3. **Mute/Unmute** during calls
4. **Using call controls**

### **9.3 Troubleshooting**
1. **Microphone not working**
2. **Calls not connecting**
3. **No incoming call UI**
4. **Registration issues**

---

## ✅ **Configuration Checklist**

### **UCM6208 Settings**
- [ ] **WebSocket enabled** on port 8088
- [ ] **SIP extension created** with credentials
- [ ] **Firewall ports** opened (8088, 5060, RTP range)
- [ ] **Extension registration** enabled
- [ ] **NAT settings** configured (if needed)

### **SIP Client Settings**
- [ ] **Credentials updated** in source code
- [ ] **Application rebuilt** with new settings
- [ ] **Files deployed** to web server
- [ ] **HTTPS configured** for production

### **Testing Completed**
- [ ] **WebSocket connection** working
- [ ] **SIP registration** successful
- [ ] **Incoming calls** displaying UI
- [ ] **Outgoing calls** functioning
- [ ] **Microphone permissions** granted
- [ ] **Call controls** working properly

---

## 📞 **Support Information**

**For technical support:**
- **Contact your development team**
- **Provide UCM6208 logs** if issues occur
- **Include browser console** errors
- **Specify exact error messages**

**Version**: 1.0.0  
**Compatibility**: Grandstream UCM6208 Series  
**Last Updated**: July 2025 