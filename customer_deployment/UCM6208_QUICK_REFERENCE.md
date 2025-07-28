# UCM6208 Quick Reference Card

## 🚀 **Quick Setup (5 Minutes)**

### **1. Access UCM6208**
```
URL: http://YOUR_UCM6208_IP
Login: admin / admin
```

### **2. Enable WebSocket**
```
System → WebSocket Settings
├── Enable WebSocket: Yes
├── Port: 8088
└── Save Settings
```

### **3. Create SIP Extension**
```
Extensions → SIP Extensions → Add Extension
├── Extension: 002
├── Name: Web Client
├── Password: tr123
├── Registration: Enabled
└── Save
```

### **4. Update SIP Client**
```dart
// In lib/controllers/simple_call_controller.dart
void register() {
  sipService.register(
    username: '002',                    // Your extension
    password: 'tr123',                  // Your password
    domain: 'YOUR_UCM6208_IP',         // Your UCM6208 IP
    wsUri: 'ws://YOUR_UCM6208_IP:8088/ws',
  );
}
```

### **5. Rebuild & Deploy**
```bash
flutter build web --release
# Copy build/web/* to your web server
```

---

## 🔧 **Essential Ports**

| Port | Protocol | Purpose |
|------|----------|---------|
| 8088 | TCP | WebSocket |
| 5060 | UDP/TCP | SIP |
| 10000-20000 | UDP | RTP Media |

---

## 🧪 **Quick Test**

### **Test WebSocket**
```bash
telnet YOUR_UCM6208_IP 8088
# Should connect successfully
```

### **Test SIP Registration**
1. Open application in browser
2. Check console for: "SIP helper started successfully"
3. Look for: "Registration state changed: registered"

### **Test Calls**
1. **Incoming**: Call extension 002 from another phone
2. **Outgoing**: Enter extension in app and click "Call"
3. **Controls**: Test answer, reject, hang up, mute

---

## 🔍 **Common Issues**

| Issue | Solution |
|-------|----------|
| WebSocket failed | Check port 8088 is open |
| Registration failed | Verify extension credentials |
| No incoming UI | Check SIP registration status |
| Microphone denied | Allow in browser settings |

---

## 📞 **Support**

**For help**: Contact your development team  
**Version**: 1.0.0  
**Compatibility**: Grandstream UCM6208 Series 