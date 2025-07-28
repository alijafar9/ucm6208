# Flutter Web SIP Client for Grandstream UCM6208

## 📱 Overview
This is a modern, responsive web-based SIP client designed to work with Grandstream UCM6208 systems. It provides a beautiful incoming call interface and full call management capabilities.

## 🚀 Features
- ✅ **Beautiful incoming call UI** with caller information and answer/decline buttons
- ✅ **SIP registration** with automatic reconnection
- ✅ **Incoming call handling** with visual notifications
- ✅ **Outgoing call support** with extension dialing
- ✅ **Call controls** including hang up, mute, and unmute
- ✅ **Responsive design** that works on desktop and mobile browsers
- ✅ **Error handling** with user-friendly messages

## 📋 Requirements
- **Web Server**: Any modern web server (Apache, Nginx, IIS, etc.)
- **HTTPS**: Required for microphone access in most browsers
- **Grandstream UCM6208**: Configured with WebSocket support
- **Modern Browser**: Chrome, Firefox, Safari, or Edge

## 🛠️ Installation

### 1. Deploy to Web Server
Copy all files from the `web` folder to your web server's document root.

### 2. Configure SIP Settings
Before using the app, you need to update the SIP configuration in the source code:

1. Open `lib/controllers/simple_call_controller.dart`
2. Update the `register()` method with your UCM6208 settings:

```dart
void register() {
  sipService.register(
    username: 'YOUR_EXTENSION',      // Your SIP extension number
    password: 'YOUR_PASSWORD',       // Your SIP password
    domain: 'YOUR_UCM_IP',          // Your UCM6208 IP address
    wsUri: 'ws://YOUR_UCM_IP:8088/ws', // WebSocket URL
  );
}
```

### 3. Rebuild the Application
After updating the configuration:

```bash
flutter build web --release
```

## 🔧 Configuration

### UCM6208 Setup
1. **Enable WebSocket**: In UCM6208 admin panel, enable WebSocket support
2. **Create SIP Extension**: Create a SIP extension for the web client
3. **Configure WebSocket Port**: Ensure port 8088 is open for WebSocket connections
4. **Firewall**: Allow WebSocket traffic on port 8088

### Browser Permissions
- **Microphone Access**: Users must allow microphone access when prompted
- **HTTPS Required**: For production use, HTTPS is required for media access

## 📞 Usage

### Incoming Calls
When an incoming call arrives:
1. **Beautiful call card** appears with caller information
2. **Green "Answer" button** to accept the call
3. **Red "Decline" button** to reject the call
4. **Caller information** displays name and number

### Outgoing Calls
1. **Enter extension** in the text field
2. **Click "Call"** to initiate outgoing call
3. **Use call controls** during the call

### Call Controls
- **Hang Up**: End the current call
- **Mute/Unmute**: Toggle microphone
- **Answer/Decline**: Handle incoming calls

## 🔍 Troubleshooting

### Common Issues

**1. No Incoming Call UI**
- Check browser console for errors
- Verify SIP registration is successful
- Ensure WebSocket connection is established

**2. Microphone Not Working**
- Check browser permissions
- Ensure HTTPS is enabled
- Try refreshing the page

**3. SIP Registration Fails**
- Verify UCM6208 IP address
- Check username/password
- Ensure WebSocket port is open

**4. WebSocket Connection Issues**
- Check firewall settings
- Verify UCM6208 WebSocket is enabled
- Try different browser

### Debug Information
The app includes debug information at the top of the screen showing:
- SIP registration status
- Incoming call detection
- Call state information

## 📱 Browser Compatibility
- ✅ **Chrome** (Recommended)
- ✅ **Firefox**
- ✅ **Safari**
- ✅ **Edge**

## 🔒 Security Notes
- Use HTTPS in production for media access
- Configure proper firewall rules
- Regularly update SIP credentials
- Monitor access logs

## 📞 Support
For technical support or customization requests, contact your development team.

---

**Version**: 1.0.0  
**Built**: July 2025  
**Compatibility**: Grandstream UCM6208 Series 