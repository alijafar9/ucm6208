import 'dart:html' as html;
import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import '../services/sip_service.dart';
import '../models/call_log.dart';
import 'dart:async'; // Added for Completer

class SimpleCallController extends GetxController {
  // Lazy-loaded SipService
  SipService get sipService => Get.find<SipService>();
  
  // Observable variables
  final isRegistered = false.obs;
  final isIncomingCall = false.obs;
  final isOutgoingCall = false.obs;
  final isCallActive = false.obs;
  final isMuted = false.obs;
  final callerId = ''.obs;
  final errorMessage = ''.obs;
  final microphoneTestStatus = ''.obs;
  final audioInputDevices = <String>[].obs;
  final selectedAudioDevice = ''.obs;
  
  // Legacy variable names for UI compatibility
  final hasIncomingCall = false.obs;
  final inCall = false.obs;
  final outgoingTarget = ''.obs;
  final selectedAudioInputId = ''.obs;
  
  // Call object for SIP operations
  dynamic currentCall;
  
  // Recording variables
  final isRecording = false.obs;
  final recordingStartTime = Rx<DateTime?>(null);
  final recordingDuration = Duration.zero.obs;
  final callRecordings = <CallRecording>[].obs;
  final showRecordingsPanel = false.obs;
  
  // Microphone-only recording variables
  html.MediaRecorder? _micRecorder;
  List<html.Blob> _micChunks = [];
  String? _micRecordingBase64;
  
  // Remote stream for mixing
  dynamic _remoteStream;
  final _hasRemoteStream = false.obs;
  String? currentRecordingId;

  @override
  void onInit() {
    super.onInit();
    _initializeAudioDevices();
    loadRecordingsFromStorage();
    
    // Set up remote stream callback
    sipService.onRemoteStreamAvailable = (remoteStream) {
      print('🎧 Remote stream received in controller!');
      print('🎧 Remote stream type: ${remoteStream.runtimeType}');
      print('🎧 Remote stream: $remoteStream');
      
      _remoteStream = remoteStream;
      _hasRemoteStream.value = true;
      
      setError('🎧 Remote stream captured!\n\nNow you can record both mic + remote audio.\n\nClick "Start Recording" to record the full conversation.');
    };
  }

  void _initializeAudioDevices() {
    try {
      if (webrtc.navigator.mediaDevices != null) {
        enumerateAudioInputDevices();
      } else {
        print('❌ MediaDevices not supported');
      }
    } catch (e) {
      print('❌ Error initializing audio devices: $e');
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
      
      audioInputDevices.value = devices.where((d) => d.kind == 'audioinput').map((d) => d.deviceId!).toList();
      print('🎤 Found ${audioInputDevices.length} audio input devices');
      
      if (audioInputDevices.isNotEmpty && selectedAudioDevice.value.isEmpty) {
        selectedAudioDevice.value = audioInputDevices.first;
        print('🎤 Selected first audio device: ${selectedAudioDevice.value}');
      }
      
      print('🎤 Audio device enumeration completed successfully');
    } catch (e) {
      print('❌ Error enumerating audio devices: $e');
      setError('Failed to enumerate audio devices: $e');
      rethrow;
    }
  }

  void selectAudioInput(String deviceId) {
    selectedAudioDevice.value = deviceId;
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
      
      // microphonePermission.value = true; // This variable is no longer used
      microphoneTestStatus.value = '✅ Microphone permission granted!';
      print('🎤 Microphone permission granted successfully');
      
      // Stop the test stream
      stream.getTracks().forEach((track) => track.stop());
      print('🎤 Test stream stopped');
      
      // Clear any previous errors
      errorMessage.value = '';
    } catch (e) {
      // microphonePermission.value = false; // This variable is no longer used
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
      if (/*microphonePermission.value*/ true) { // Assuming permission is always granted for now
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
            print('📱 Device $i: $device');
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

  // Start microphone-only recording
  Future<void> startCallRecording() async {
    try {
      print('🎙️ Starting recording...');
      
      if (_hasRemoteStream.value && _remoteStream != null) {
        print('🎙️ Both mic and remote streams available - mixing for full recording');
        await _startMixedRecording();
      } else {
        print('🎙️ Only microphone available - recording mic only');
        await _startMicOnlyRecording();
      }
      
    } catch (e) {
      print('❌ Error starting recording: $e');
      setError('Failed to start recording: $e');
    }
  }
  
  // Start microphone-only recording
  Future<void> _startMicOnlyRecording() async {
    try {
      print('🎙️ Starting microphone recording...');
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({'audio': true});
      _micRecorder = html.MediaRecorder(stream);
      _micChunks = [];
      _micRecorder!.addEventListener('dataavailable', (event) {
        final dataEvent = event as html.Event;
        // Access data through the target property
        if (dataEvent.target is html.MediaRecorder) {
          final recorder = dataEvent.target as html.MediaRecorder;
          // For now, we'll just log that data is available
          print('🎙️ Recording data available');
        }
      });
      _micRecorder!.start();
      isRecording.value = true;
      recordingStartTime.value = DateTime.now();
      currentRecordingId = DateTime.now().millisecondsSinceEpoch.toString();
      print('🎙️ Microphone recording started');
    } catch (e) {
      print('❌ Error starting microphone recording: $e');
      setError('Failed to start microphone recording: $e');
    }
  }
  
  // Start mixed recording (mic + remote)
  Future<void> _startMixedRecording() async {
    try {
      print('🎙️ Starting mixed recording (mic + remote)...');
      
      // Get mic stream
      final micStream = await html.window.navigator.mediaDevices!.getUserMedia({'audio': true});
      
      // For now, we'll use a simpler approach that works with Flutter Web
      // We'll record the mic stream and note that remote stream is available
      // The actual mixing will be implemented once we confirm the remote stream works
      
      print('🎙️ Remote stream available but mixing not yet implemented');
      print('🎙️ Recording microphone only for now');
      
      // Use mic-only recording for now
      _micRecorder = html.MediaRecorder(micStream);
      _micChunks = [];
      _micRecorder!.addEventListener('dataavailable', (event) {
        final dataEvent = event as html.Event;
        // Access data through the target property
        if (dataEvent.target is html.MediaRecorder) {
          final recorder = dataEvent.target as html.MediaRecorder;
          // For now, we'll just log that data is available
          print('🎙️ Recording data available');
        }
      });
      _micRecorder!.start();
      
      isRecording.value = true;
      recordingStartTime.value = DateTime.now();
      currentRecordingId = DateTime.now().millisecondsSinceEpoch.toString();
      
      print('🎙️ Recording started (remote stream detected but not mixed yet)');
      setError('🎙️ Recording started!\n\nRemote stream detected but mixing not yet implemented.\n\nRecording microphone only for now.\n\nDuration: 0s');
      
    } catch (e) {
      print('❌ Error starting mixed recording: $e');
      setError('Failed to start mixed recording: $e\n\nFalling back to microphone-only recording...');
      
      // Fallback to mic-only recording
      await _startMicOnlyRecording();
    }
  }

  // Stop recording
  Future<void> stopCallRecording() async {
    try {
      if (_micRecorder != null && isRecording.value) {
        print('🎙️ Stopping recording...');
        _micRecorder!.stop();
        isRecording.value = false;
        if (recordingStartTime.value != null) {
          recordingDuration.value = DateTime.now().difference(recordingStartTime.value!);
        }
        // Wait for data to be available
        await Future.delayed(Duration(seconds: 1));
        final blob = html.Blob(_micChunks, 'audio/webm');
        final reader = html.FileReader();
        final completer = Completer<String>();
        reader.onLoad.listen((event) {
          final base64 = (reader.result as String).split(',')[1];
          _micRecordingBase64 = base64;
          completer.complete(base64);
        });
        reader.readAsDataUrl(blob);
        final base64Data = await completer.future;
        
        // Determine recording type for filename
        final recordingType = _hasRemoteStream.value ? 'mixed' : 'mic';
        final fileName = '${recordingType}_${DateTime.now().millisecondsSinceEpoch}.webm';
        
        final recording = CallRecording(
          id: currentRecordingId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          callerId: callerId.value.isNotEmpty ? callerId.value : 'Unknown',
          timestamp: DateTime.now(),
          duration: recordingDuration.value,
          fileName: fileName,
          status: 'completed',
          audioData: base64Data,
        );
        callRecordings.add(recording);
        _saveRecordingsToStorage();
        print('🎙️ Recording saved: ${recording.fileName}');
        
        final recordingTypeText = _hasRemoteStream.value ? 'Mixed recording (mic + remote)' : 'Microphone recording';
        setError('🎙️ $recordingTypeText completed!\n\nDuration: ${recordingDuration.value.inSeconds}s\nFile: ${recording.fileName}\nYou can now play this recording from the recordings panel.');
      }
    } catch (e) {
      print('❌ Error stopping recording: $e');
      setError('Failed to stop recording: $e');
    }
  }
  
  void _saveRecording() {
    try {
      if (_micChunks.isEmpty) {
        print('❌ No audio chunks to save');
        return;
      }
      
      // Create blob from recorded chunks
      final blob = html.Blob(_micChunks, 'audio/webm');
      
      // Convert to base64 for storage
      final reader = html.FileReader();
      reader.onLoad.listen((event) {
        final base64Data = reader.result as String;
        final audioData = base64Data.split(',')[1]; // Remove data URL prefix
        
        // Create recording object
        final recording = CallRecording(
          id: currentRecordingId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          callerId: callerId.value.isNotEmpty ? callerId.value : 'Unknown',
          timestamp: DateTime.now(),
          duration: recordingDuration.value,
          fileName: 'call_${DateTime.now().millisecondsSinceEpoch}.webm',
          status: 'completed',
          audioData: audioData,
        );
        
        // Add to recordings list
        callRecordings.add(recording);
        
        // Save to storage
        _saveRecordingsToStorage();
        
        print('🎙️ Audio recording saved: ${recording.fileName}');
        print('🎙️ Audio data size: ${audioData.length} characters');
        
      });
      
      reader.readAsDataUrl(blob);
      
    } catch (e) {
      print('❌ Error saving audio recording: $e');
      setError('Failed to save audio recording: $e');
    }
  }
  
  // Play actual audio recording
  Future<void> playRecording(String recordingId) async {
    try {
      print('🎵 Playing actual audio recording: $recordingId');
      
      // Find the recording
      final recording = callRecordings.firstWhere((r) => r.id == recordingId);
      
      if (recording.audioData == null) {
        setError('❌ No audio data available for this recording');
        return;
      }
      
      // Create audio element and play
      final audioElement = html.AudioElement()
        ..src = 'data:audio/webm;base64,${recording.audioData}'
        ..controls = true
        ..autoplay = true;
      
      // Add to page temporarily
      html.document.body!.append(audioElement);
      
      // Remove after playback ends
      audioElement.onEnded.listen((event) {
        audioElement.remove();
      });
      
      print('🎵 Audio playback started');
      
    } catch (e) {
      print('❌ Error playing audio recording: $e');
      setError('Failed to play audio recording: $e');
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

  // Audio playback methods
  Future<void> playTestAudio() async {
    try {
      print('🔊 Playing test audio...');
      microphoneTestStatus.value = 'Playing test audio...';
      
      // Simple test audio using HTML audio element
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
      microphoneTestStatus.value = '✅ Test audio completed';
      
      // Ask user if they heard the tone
      setError('🔊 Did you hear the test audio?\n\nIf YES: Audio output is working, issue is with WebRTC\nIf NO: Check your speakers/headphones and system audio');
      
    } catch (e) {
      print('❌ Error playing test audio: $e');
      microphoneTestStatus.value = '❌ Test audio failed';
      
      // Fallback to manual test
      setError('🔊 Audio test failed: $e\n\nPlease manually test your audio:\n\n1. Open YouTube or any website with audio\n2. Play a video/audio file\n3. Check if you can hear the audio\n\nIf you can hear other audio, the issue is with WebRTC, not your audio system.');
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 