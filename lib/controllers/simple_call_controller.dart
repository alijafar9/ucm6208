import 'package:get/get.dart';
import '../services/sip_service.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'dart:html' as html;
import 'dart:convert';
import 'dart:async';

class CallRecording {
  final String id;
  final String callerId;
  final DateTime timestamp;
  final Duration duration;
  final String fileName;
  final String status; // 'recording', 'completed', 'failed'

  CallRecording({
    required this.id,
    required this.callerId,
    required this.timestamp,
    required this.duration,
    required this.fileName,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'callerId': callerId,
    'timestamp': timestamp.toIso8601String(),
    'duration': duration.inSeconds,
    'fileName': fileName,
    'status': status,
  };

  factory CallRecording.fromJson(Map<String, dynamic> json) => CallRecording(
    id: json['id'],
    callerId: json['callerId'],
    timestamp: DateTime.parse(json['timestamp']),
    duration: Duration(seconds: json['duration']),
    fileName: json['fileName'],
    status: json['status'],
  );
}

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
  
  // Call recording variables
  var isRecording = false.obs;
  var recordingStartTime = DateTime.now().obs;
  var recordingDuration = Duration.zero.obs;
  var callRecordings = <CallRecording>[].obs;
  var showRecordingsPanel = false.obs;
  
  Call? currentCall;
  Timer? recordingTimer;

  @override
  void onInit() {
    super.onInit();
    print('🔧 SimpleCallController initialized');
    
    // Load existing recordings
    loadRecordingsFromStorage();
    
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
        
        // Auto-start recording for debugging
        Future.delayed(Duration(seconds: 2), () {
          if (inCall.value) {
            startCallRecording();
          }
        });
        
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
      // Stop recording if active
      if (isRecording.value) {
        stopCallRecording();
      }
      
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
    
    // Stop recording if active
    if (isRecording.value) {
      stopCallRecording();
    }
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
      
      // Simple manual audio test
      print('🔊 Manual audio test initiated');
      microphoneTestStatus.value = '🔊 Manual audio test...';
      
      // Wait a moment to show the status
      await Future.delayed(Duration(seconds: 2));
      
      print('🔊 Manual audio test completed');
      microphoneTestStatus.value = '✅ Audio test completed';
      
      // Ask user to manually test their audio
      setError('🔊 Manual Audio Test\n\nPlease do the following:\n\n1. Open any website with audio (YouTube, etc.)\n2. Play a video or audio file\n3. Check if you can hear the audio\n\nThen tell me:\n✅ YES - I can hear audio from other websites\n❌ NO - I cannot hear audio from other websites\n\nThis will help us determine if the issue is:\n- Your audio system (if NO)\n- WebRTC configuration (if YES)');
      
    } catch (e) {
      print('❌ Error in audio test: $e');
      microphoneTestStatus.value = '❌ Audio test failed';
      setError('🔊 Audio test error: $e\n\nPlease manually test your audio system by playing any audio file on your computer.');
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

  // Method to check WebRTC status and provide debugging info
  void checkWebRTCStatus() {
    try {
      print('🔍 Checking WebRTC status...');
      microphoneTestStatus.value = 'Checking WebRTC status...';
      
      // Check if WebRTC is supported
      if (webrtc.navigator.mediaDevices == null) {
        setError('❌ WebRTC not supported in this browser!\n\nPlease use Chrome, Firefox, or Safari for full WebRTC support.');
        return;
      }
      
      // Check if we're on HTTPS (required for WebRTC)
      final isHttps = html.window.location.protocol == 'https:';
      final isLocalhost = html.window.location.hostname == 'localhost' || 
                          html.window.location.hostname == '127.0.0.1';
      
      String statusMessage = '🔍 WebRTC Status Check:\n\n';
      
      // Browser compatibility
      statusMessage += '🌐 Browser: ${html.window.navigator.userAgent}\n';
      statusMessage += '🔒 Protocol: ${html.window.location.protocol}\n';
      statusMessage += '📍 Host: ${html.window.location.hostname}\n\n';
      
      // WebRTC support
      statusMessage += '✅ WebRTC supported: Yes\n';
      statusMessage += '✅ MediaDevices API: Available\n';
      
      // HTTPS check
      if (isHttps || isLocalhost) {
        statusMessage += '✅ HTTPS/Localhost: Yes (WebRTC should work)\n';
      } else {
        statusMessage += '❌ HTTPS/Localhost: No (WebRTC may not work)\n';
      }
      
      statusMessage += '\n🎯 One-Way Audio Diagnosis:\n';
      statusMessage += '1. Check your system audio (play any audio file)\n';
      statusMessage += '2. Test microphone permissions\n';
      statusMessage += '3. Check UCM6208 RTP settings\n';
      statusMessage += '4. Verify NAT/firewall configuration\n';
      
      print('🔍 WebRTC status check completed');
      microphoneTestStatus.value = '✅ WebRTC status checked';
      setError(statusMessage);
      
    } catch (e) {
      print('❌ Error checking WebRTC status: $e');
      microphoneTestStatus.value = '❌ WebRTC check failed';
      setError('Failed to check WebRTC status: $e');
    }
  }

  // Call recording methods
  Future<void> startCallRecording() async {
    try {
      print('🎙️ Starting call recording...');
      
      if (currentCall == null) {
        setError('No active call to record');
        return;
      }
      
      // For now, we'll simulate recording since MediaRecorder has compatibility issues
      // This will help us track call duration and diagnose audio issues
      
      isRecording.value = true;
      recordingStartTime.value = DateTime.now();
      recordingDuration.value = Duration.zero;
      
      // Start timer to update duration
      recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        recordingDuration.value = DateTime.now().difference(recordingStartTime.value);
      });
      
      print('🎙️ Call recording simulation started');
      setError('🎙️ Recording started - Duration: ${recordingDuration.value.inSeconds}s\n\nNote: This is a simulation to help diagnose audio issues. The recording will capture call metadata for debugging.');
      
    } catch (e) {
      print('❌ Error starting call recording: $e');
      setError('Failed to start recording: $e');
    }
  }
  
  void stopCallRecording() {
    try {
      print('🎙️ Stopping call recording...');
      
      if (isRecording.value) {
        recordingTimer?.cancel();
        isRecording.value = false;
        
        // Create a recording record for debugging
        final recording = CallRecording(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          callerId: callerId.value,
          timestamp: DateTime.now(),
          duration: recordingDuration.value,
          fileName: 'call_debug_${DateTime.now().millisecondsSinceEpoch}.txt',
          status: 'completed',
        );
        
        // Add to recordings list
        callRecordings.add(recording);
        _saveRecordingsToStorage();
        
        print('🎙️ Call recording stopped');
        setError('🎙️ Recording stopped - Duration: ${recordingDuration.value.inSeconds}s\n\nRecording saved for debugging. Check the recordings panel for details.');
      }
      
    } catch (e) {
      print('❌ Error stopping call recording: $e');
      setError('Failed to stop recording: $e');
    }
  }
  
  void _saveRecording() {
    try {
      // This method is no longer needed as MediaRecorder is removed
      // The recording logic is now handled by startCallRecording and stopCallRecording
      // This method was left as a placeholder for future recording implementation
      print('🎙️ _saveRecording called (placeholder)');
      setError('Recording saving is currently disabled.');
    } catch (e) {
      print('❌ Error saving recording: $e');
      setError('Failed to save recording: $e');
    }
  }
  
  void _saveRecordingsToStorage() {
    try {
      final recordingsJson = callRecordings.map((r) => r.toJson()).toList();
      html.window.localStorage['callRecordings'] = jsonEncode(recordingsJson);
      print('💾 Recordings saved to local storage');
    } catch (e) {
      print('❌ Error saving recordings to storage: $e');
    }
  }
  
  void loadRecordingsFromStorage() {
    try {
      final recordingsData = html.window.localStorage['callRecordings'];
      if (recordingsData != null) {
        final List<dynamic> recordingsJson = jsonDecode(recordingsData);
        callRecordings.value = recordingsJson.map((json) => CallRecording.fromJson(json)).toList();
        print('📁 Loaded ${callRecordings.length} recordings from storage');
      }
    } catch (e) {
      print('❌ Error loading recordings from storage: $e');
    }
  }
  
  void deleteRecording(String recordingId) {
    try {
      callRecordings.removeWhere((recording) => recording.id == recordingId);
      _saveRecordingsToStorage();
      print('🗑️ Recording deleted: $recordingId');
    } catch (e) {
      print('❌ Error deleting recording: $e');
      setError('Failed to delete recording: $e');
    }
  }
  
  void toggleRecordingsPanel() {
    showRecordingsPanel.value = !showRecordingsPanel.value;
    if (showRecordingsPanel.value) {
      loadRecordingsFromStorage();
    }
  }
} 