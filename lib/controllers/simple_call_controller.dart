import 'package:get/get.dart';
import '../services/sip_service.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'dart:html' as html;

class SimpleCallController extends GetxController {
  final SipService sipService = SipService();

  var callerId = ''.obs;
  var hasIncomingCall = false.obs;
  var outgoingTarget = ''.obs;
  var inCall = false.obs;
  var isMuted = false.obs;
  var errorMessage = ''.obs;
  var audioInputDevices = <webrtc.MediaDeviceInfo>[].obs;
  var selectedAudioInputId = ''.obs;
  var microphonePermission = false.obs;
  var microphoneTestStatus = ''.obs;
  Call? currentCall;

  @override
  void onInit() {
    super.onInit();
    print('🔧 SimpleCallController initialized');
    
    sipService.onIncomingCall = (call, id) {
      print('📞 INCOMING CALL DETECTED!');
      print('📞 Caller ID: $id');
      print('📞 Call object: $call');
      
      currentCall = call;
      callerId.value = id;
      hasIncomingCall.value = true;
      
      print('📞 hasIncomingCall set to: ${hasIncomingCall.value}');
      print('📞 callerId set to: ${callerId.value}');
      print('📞 UI should now show incoming call interface');
    };
    
    sipService.onError = (error) {
      print('❌ SIP Error: $error');
      setError(error);
    };
    
    // Don't initialize audio devices automatically - let user do it manually
    // This avoids permission issues on page load
    register(); // Auto-register on startup
  }

  Future<void> _initializeAudioDevices() async {
    try {
      print('🎤 Initializing audio devices...');
      await enumerateAudioInputDevices();
      print('🎤 Audio devices initialized successfully');
    } catch (e) {
      print('❌ Error initializing audio devices: $e');
      // Don't set error here as it might be a permission issue that will be resolved later
    }
  }

  Future<void> enumerateAudioInputDevices() async {
    try {
      print('🎤 Enumerating audio input devices...');
      
      // Check if WebRTC is supported
      if (webrtc.navigator.mediaDevices == null) {
        throw Exception('WebRTC not supported in this browser. Please use Chrome, Firefox, or Safari.');
      }
      
      // First, request microphone permission with more specific constraints
      try {
        final stream = await webrtc.navigator.mediaDevices.getUserMedia({
          'audio': {
            'echoCancellation': true,
            'noiseSuppression': true,
            'autoGainControl': true,
            'sampleRate': 8000, // Match SIP codec requirements
            'channelCount': 1,  // Mono for voice calls
          }
        });
        print('🎤 Microphone permission granted');
        
        // Stop the permission test stream immediately
        stream.getTracks().forEach((track) => track.stop());
        print('🎤 Permission test stream stopped');
      } catch (e) {
        print('❌ Microphone permission denied: $e');
        
        // Provide specific guidance based on error type
        if (e.toString().contains('Null check operator used on a null value')) {
          throw Exception('WebRTC not supported in this browser. Please use Chrome, Firefox, or Safari.');
        } else if (e.toString().contains('NotAllowedError')) {
          throw Exception('Microphone access denied. Please:\n1. Click the microphone icon in your browser address bar\n2. Select "Allow"\n3. Refresh the page');
        } else if (e.toString().contains('NotFoundError')) {
          throw Exception('No microphone found. Please:\n1. Connect a microphone or headset\n2. Check if it\'s working in other applications\n3. Refresh the page');
        } else if (e.toString().contains('NotSupportedError')) {
          throw Exception('Microphone not supported. Please:\n1. Use a modern browser (Chrome, Firefox, Safari)\n2. Ensure HTTPS is enabled for production');
        } else {
          throw Exception('Microphone error: $e\nPlease check your microphone and browser settings.');
        }
      }
      
      // Now enumerate devices
      final devices = await webrtc.navigator.mediaDevices.enumerateDevices();
      print('🎤 Found ${devices.length} total devices');
      
      audioInputDevices.value = devices.where((d) => d.kind == 'audioinput').toList();
      print('🎤 Found ${audioInputDevices.length} audio input devices');
      
      if (audioInputDevices.isNotEmpty && selectedAudioInputId.value.isEmpty) {
        selectedAudioInputId.value = audioInputDevices.first.deviceId ?? '';
        print('🎤 Selected first audio device: ${selectedAudioInputId.value}');
      }
      
      print('🎤 Audio device enumeration completed successfully');
    } catch (e) {
      print('❌ Error enumerating audio devices: $e');
      setError('Failed to enumerate audio devices: $e');
      rethrow;
    }
  }

  void selectAudioInput(String deviceId) {
    selectedAudioInputId.value = deviceId;
  }

  void register() {
    sipService.register(
      username: '003',
      password: 'tr123',
      domain: '172.16.26.2',
      wsUri: 'ws://172.16.26.2:8088/ws',
    );
  }

  void answerCall() {
    if (currentCall != null) {
      try {
        print('📞 Attempting to answer call...');
        sipService.answerWithCodecFallback(currentCall!);
        inCall.value = true;
        hasIncomingCall.value = false;
        print('📞 Call answered successfully');
      } catch (e) {
        print('❌ Error answering call: $e');
        
        // Check if it's a codec error
        if (e.toString().contains('G726-32') || e.toString().contains('payload type')) {
          setError('Codec compatibility issue. Try calling from a different phone or contact administrator.');
        } else {
          setError('Failed to answer call: $e');
        }
        
        _resetCallState();
      }
    }
  }

  void rejectCall() {
    if (currentCall != null) {
      try {
        sipService.reject(currentCall!);
        print('📞 Call rejected successfully');
      } catch (e) {
        print('❌ Error rejecting call: $e');
        setError('Failed to reject call: $e');
      } finally {
        _resetCallState();
      }
    }
  }

  void makeOutgoingCall() {
    if (outgoingTarget.value.isNotEmpty) {
      try {
        sipService.makeCall(outgoingTarget.value);
        inCall.value = true;
        errorMessage.value = '';
      } catch (e) {
        setError('Unable to start call: $e');
      }
    }
  }

  void hangupCall() {
    if (currentCall != null) {
      sipService.hangupCall(currentCall!);
      _resetCallState();
      inCall.value = false;
    }
  }

  void muteCall() {
    if (currentCall != null) {
      sipService.muteMic(currentCall!);
      isMuted.value = true;
    }
  }

  void unmuteCall() {
    if (currentCall != null) {
      sipService.unmuteMic(currentCall!);
      isMuted.value = false;
    }
  }

  void setError(String msg) {
    errorMessage.value = msg;
  }

  void _resetCallState() {
    hasIncomingCall.value = false;
    callerId.value = '';
    currentCall = null;
    inCall.value = false;
    isMuted.value = false;
    errorMessage.value = '';
  }

  // Method to manually test the incoming call interface
  void testIncomingCallInterface() {
    print('🧪 Testing incoming call interface manually');
    callerId.value = 'Test Caller (900)';
    hasIncomingCall.value = true;
    print('🧪 hasIncomingCall set to: ${hasIncomingCall.value}');
    print('🧪 callerId set to: ${callerId.value}');
  }

  // Method to test audio output (speakers/headphones)
  Future<void> testAudioOutput() async {
    try {
      print('🔊 Testing audio output...');
      microphoneTestStatus.value = 'Testing audio output...';
      
      // Simple audio test using HTML audio element
      final audioElement = html.AudioElement()
        ..src = 'data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuBzvLZiTYIG2m98OScTgwOUarm7blmGgU7k9n1unEiBC13yO/eizEIHWq+8+OWT'
        ..volume = 0.5;
      
      print('🔊 Playing test audio - you should hear a beep');
      microphoneTestStatus.value = '🔊 Playing test audio... (you should hear a beep)';
      
      // Play the audio
      await audioElement.play();
      
      // Wait for audio to finish
      await Future.delayed(Duration(seconds: 3));
      
      print('🔊 Test audio completed');
      microphoneTestStatus.value = '✅ Audio output test completed';
      
      // Ask user if they heard the tone
      setError('🔊 Did you hear the test audio?\n\nIf YES: Audio output is working, issue is with WebRTC\nIf NO: Check your speakers/headphones and system audio');
      
    } catch (e) {
      print('❌ Error testing audio output: $e');
      microphoneTestStatus.value = '❌ Audio output test failed';
      setError('Failed to test audio output: $e\n\nPlease check your system audio settings and try again.');
    }
  }

  // Method to show browser-specific microphone permission guidance
  void showMicrophoneHelp() {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    String browserName = 'Unknown';
    String specificInstructions = '';
    
    if (userAgent.contains('chrome')) {
      browserName = 'Chrome';
      specificInstructions = '''
📱 Chrome Instructions:
1. Look for a microphone icon in the address bar (next to the lock icon)
2. Click the microphone icon
3. Select "Allow" from the dropdown
4. Refresh this page
5. Try "Test Microphone" again

If you don't see the microphone icon:
1. Click the lock icon in the address bar
2. Set microphone to "Allow"
3. Refresh the page
''';
    } else if (userAgent.contains('firefox')) {
      browserName = 'Firefox';
      specificInstructions = '''
🦊 Firefox Instructions:
1. Look for a microphone icon in the address bar
2. Click the microphone icon
3. Select "Allow" from the dropdown
4. Refresh this page
5. Try "Test Microphone" again

If you don't see the microphone icon:
1. Click the shield icon in the address bar
2. Set microphone to "Allow"
3. Refresh the page
''';
    } else if (userAgent.contains('safari')) {
      browserName = 'Safari';
      specificInstructions = '''
🍎 Safari Instructions:
1. Go to Safari > Preferences > Websites > Microphone
2. Set this site to "Allow"
3. Refresh this page
4. Try "Test Microphone" again

Alternative method:
1. Click Safari > Settings for This Website
2. Set microphone to "Allow"
3. Refresh the page
''';
    } else if (userAgent.contains('edge')) {
      browserName = 'Edge';
      specificInstructions = '''
🌐 Edge Instructions:
1. Look for a microphone icon in the address bar
2. Click the microphone icon
3. Select "Allow" from the dropdown
4. Refresh this page
5. Try "Test Microphone" again

If you don't see the microphone icon:
1. Click the lock icon in the address bar
2. Set microphone to "Allow"
3. Refresh the page
''';
    } else {
      specificInstructions = '''
🌐 General Instructions:
1. Look for a microphone or camera icon in your browser's address bar
2. Click it and select "Allow"
3. Refresh this page
4. Try "Test Microphone" again

If you don't see any icons:
1. Check your browser settings for microphone permissions
2. Try using Chrome, Firefox, or Safari
3. Make sure you're using HTTPS (for production)
''';
    }
    
    final helpText = '''
🔒 Microphone Permission Help

Detected Browser: $browserName

$specificInstructions

💡 Troubleshooting Tips:
• Make sure your microphone is connected and not muted
• Try a different browser if the issue persists
• Check if your browser is up to date
• For production, make sure you're using HTTPS
• Some browsers require HTTPS for microphone access

🔧 If nothing works:
1. Try Chrome, Firefox, or Safari
2. Check your microphone in other applications
3. Restart your browser
4. Check your system's microphone settings
''';
    setError(helpText);
  }

  Future<void> testMicrophonePermission() async {
    try {
      microphoneTestStatus.value = 'Testing microphone permission...';
      print('🎤 Testing microphone permission...');
      
      // Check if WebRTC is supported
      if (webrtc.navigator.mediaDevices == null) {
        throw Exception('WebRTC not supported in this browser. Please use Chrome, Firefox, or Safari.');
      }
      
      final stream = await webrtc.navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
          'sampleRate': 8000,
          'channelCount': 1,
        }
      });
      
      microphonePermission.value = true;
      microphoneTestStatus.value = '✅ Microphone permission granted!';
      print('🎤 Microphone permission granted successfully');
      
      // Stop the test stream
      stream.getTracks().forEach((track) => track.stop());
      print('🎤 Test stream stopped');
      
      // Clear any previous errors
      errorMessage.value = '';
    } catch (e) {
      microphonePermission.value = false;
      microphoneTestStatus.value = '❌ Microphone permission denied: $e';
      print('❌ Microphone permission error: $e');
      
      // Provide helpful error message with specific guidance
      if (e.toString().contains('Null check operator used on a null value')) {
        setError('🌐 WebRTC not supported!\n\nThis browser doesn\'t support WebRTC or microphone access.\n\nTo fix this:\n1. Use Chrome, Firefox, or Safari\n2. Make sure you\'re using HTTPS (for production)\n3. Check if your browser is up to date\n4. Try a different browser');
      } else if (e.toString().contains('NotAllowedError')) {
        setError('🔒 Microphone access denied!\n\nTo fix this:\n1. Look for a microphone icon in your browser address bar\n2. Click it and select "Allow"\n3. Refresh this page\n\nIf you don\'t see the icon, check your browser settings for microphone permissions.');
      } else if (e.toString().contains('NotFoundError')) {
        setError('🎤 No microphone found!\n\nTo fix this:\n1. Connect a microphone or headset\n2. Check if it works in other applications\n3. Refresh this page\n\nMake sure your microphone is not muted.');
      } else if (e.toString().contains('NotSupportedError')) {
        setError('🌐 Browser not supported!\n\nTo fix this:\n1. Use Chrome, Firefox, or Safari\n2. Make sure you\'re using HTTPS (for production)\n3. Try a different browser');
      } else {
        setError('❌ Microphone error: $e\n\nPlease check your microphone and browser settings.');
      }
    }
  }

  Future<void> listAudioDevices() async {
    try {
      microphoneTestStatus.value = 'Listing audio devices...';
      print('🎤 Listing audio devices...');
      
      // Check if WebRTC is supported
      if (webrtc.navigator.mediaDevices == null) {
        throw Exception('WebRTC not supported in this browser. Please use Chrome, Firefox, or Safari.');
      }
      
      // First test microphone permission
      await testMicrophonePermission();
      
      // If permission is granted, enumerate devices
      if (microphonePermission.value) {
        await enumerateAudioInputDevices();
        
        if (audioInputDevices.isEmpty) {
          microphoneTestStatus.value = '⚠️ No audio input devices found';
          print('⚠️ No audio input devices found');
          setError('No audio input devices found. Please connect a microphone and try again.');
        } else {
          microphoneTestStatus.value = '📱 Found ${audioInputDevices.length} audio device(s)';
          print('📱 Found ${audioInputDevices.length} audio device(s)');
          
          // List the devices for debugging
          for (int i = 0; i < audioInputDevices.length; i++) {
            final device = audioInputDevices[i];
            print('📱 Device $i: ${device.label} (${device.deviceId})');
          }
          
          // Clear any previous errors
          errorMessage.value = '';
        }
      }
    } catch (e) {
      microphoneTestStatus.value = '❌ Error listing devices: $e';
      print('❌ Error listing devices: $e');
      setError('Failed to list audio devices: $e');
    }
  }
} 