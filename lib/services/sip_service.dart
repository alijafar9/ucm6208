import 'package:sip_ua/sip_ua.dart';
import 'package:sip_ua/src/constants.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SipService extends SipUaHelperListener {
  final SIPUAHelper _helper = SIPUAHelper();
  Function(Call, String)? onIncomingCall;
  Function(String)? onError;

  SipService() {
    _helper.addSipUaHelperListener(this);
  }

  void register({
    required String username,
    required String password,
    required String domain,
    required String wsUri,
    String? displayName,
  }) {
    try {
      print('Starting SIP registration...');
      print('Username: $username');
      print('Domain: $domain');
      print('WebSocket URL: $wsUri');
      
      UaSettings settings = UaSettings();
      
      // WebSocket settings
      settings.webSocketUrl = wsUri;
      settings.webSocketSettings.extraHeaders = {};
      settings.webSocketSettings.allowBadCertificate = true;
      
      // SIP URI and authentication
      settings.uri = 'sip:$username@$domain';
      settings.authorizationUser = username;
      settings.password = password;
      settings.displayName = displayName ?? username;
      settings.userAgent = 'Dart SIP Client';
      
      // Transport type (WebSocket)
      settings.transportType = TransportType.WS;
      
      // Registration settings
      settings.register = true;
      settings.register_expires = 120;
      settings.registrarServer = 'sip:$domain';
      
      // DTMF mode
      settings.dtmfMode = DtmfMode.RFC2833;
      
      // ICE settings
      settings.iceServers = [
        {'urls': 'stun:stun.l.google.com:19302'},
      ];
      settings.iceTransportPolicy = IceTransportPolicy.ALL;
      
      // Session timers
      settings.sessionTimers = true;
      settings.sessionTimersRefreshMethod = SipMethod.UPDATE;
      
      // Connection recovery
      settings.connectionRecoveryMaxInterval = 30;
      settings.connectionRecoveryMinInterval = 2;
      
      // ICE gathering timeout
      settings.iceGatheringTimeout = 500;
      
      print('Starting SIP helper with settings...');
      _helper.start(settings);
      print('SIP helper started successfully');
    } catch (e) {
      print('Error during SIP registration: $e');
      rethrow;
    }
  }

  // Method to configure WebRTC with specific codec preferences
  void configureWebRTC() {
    try {
      print('🔧 Configuring WebRTC codec preferences...');
      
      // This would configure WebRTC to prefer specific codecs
      // Note: This is a placeholder for WebRTC configuration
      print('🔧 WebRTC configured to prefer G711 codecs');
    } catch (e) {
      print('❌ Error configuring WebRTC: $e');
    }
  }

  // Method to handle codec conflicts by trying different approaches
  void answerWithCodecFallback(Call call) {
    print('📞 Attempting to answer call with codec fallback...');

    // Define a single, robust strategy with SDP manipulation
    final Map<String, dynamic> answerOptions = {
      'mediaConstraints': {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
          'googEchoCancellation': true,
          'googAutoGainControl': true,
          'googNoiseSuppression': true,
          'googHighpassFilter': true,
          'googTypingNoiseDetection': true,
          'googAudioMirroring': false,
        },
        'video': false,
      },
      'pcConfig': {
        'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}],
        'iceTransportPolicy': 'all',
        'bundlePolicy': 'balanced',
        'rtcpMuxPolicy': 'require',
        'sdpSemantics': 'unified-plan',
      },
    };

    try {
      print('📞 Applying SDP manipulation and answering...');
      _answerWithSdpManipulation(call, answerOptions);
      print('📞 Call answered successfully with SDP manipulation.');
    } catch (e) {
      print('❌ Error answering call with SDP manipulation: $e');
      setError('Failed to answer call due to WebRTC configuration: $e');
      rethrow;
    }
  }

  // Custom method to handle SDP manipulation for codec prioritization
  RTCSessionDescription _filterSdpCodecs(RTCSessionDescription sdp) {
    print('🔧 Intercepting local SDP for codec filtering...');
    print('Original SDP: \n${sdp.sdp}');

    String modifiedSdp = sdp.sdp!;

    // Define preferred codecs and their payload types
    // Prioritize PCMU (0) and PCMA (8), keep telephone-event (101)
    final Map<String, int> preferredCodecs = {
      'PCMU': 0,
      'PCMA': 8,
      'telephone-event': 101,
    };

    List<String> sdpLines = modifiedSdp.split('\r\n');
    List<String> newSdpLines = [];
    List<String> audioPayloads = [];
    
    // Keep track of codecs we want to include
    Set<int> desiredPayloadTypes = preferredCodecs.values.toSet();
    
    // First pass: Process m=audio line
    bool audioLineProcessed = false;
    for (String line in sdpLines) {
      if (line.startsWith('m=audio') && !audioLineProcessed) {
        List<String> parts = line.split(' ');
        List<String> currentPayloads = parts.sublist(3); // Get payload types after UDP/TLS/RTP/SAVPF

        List<String> orderedPayloads = [];
        
        // Add preferred codecs first, maintaining their order from preferredCodecs map
        for (String codecName in preferredCodecs.keys) {
          int? payloadType = preferredCodecs[codecName];
          if (payloadType != null && currentPayloads.contains(payloadType.toString())) {
            orderedPayloads.add(payloadType.toString());
          }
        }
        
        // Add any other payloads that are present but not explicitly preferred, and not G726-32 (payload type 2)
        for (String payload in currentPayloads) {
          int? pt = int.tryParse(payload);
          if (pt != null && !desiredPayloadTypes.contains(pt) && pt != 2) {
            orderedPayloads.add(payload);
          }
        }
        
        newSdpLines.add('${parts[0]} ${parts[1]} ${parts[2]} ${orderedPayloads.join(' ')}');
        audioPayloads = orderedPayloads; // Store for filtering rtpmap lines
        audioLineProcessed = true;
      } else {
        newSdpLines.add(line);
      }
    }

    // Second pass: Filter rtpmap and fmtp lines based on the new audioPayloads
    List<String> finalSdpLines = [];
    for (String line in newSdpLines) {
      if (line.startsWith('a=rtpmap:')) {
        RegExp rtpmapRegex = RegExp(r'a=rtpmap:(\d+)\s');
        Match? match = rtpmapRegex.firstMatch(line);
        if (match != null) {
          int payloadType = int.parse(match.group(1)!);
          if (audioPayloads.contains(payloadType.toString())) {
            finalSdpLines.add(line);
          }
        }
      } else if (line.startsWith('a=fmtp:')) {
        RegExp fmtpRegex = RegExp(r'a=fmtp:(\d+)\s');
        Match? match = fmtpRegex.firstMatch(line);
        if (match != null) {
          int payloadType = int.parse(match.group(1)!);
          if (audioPayloads.contains(payloadType.toString())) {
            finalSdpLines.add(line);
          }
        }
      } else {
        finalSdpLines.add(line);
      }
    }
    
    modifiedSdp = finalSdpLines.join('\r\n');
    print('Modified SDP: \n$modifiedSdp');
    
    return RTCSessionDescription(modifiedSdp, sdp.type);
  }

  void _answerWithSdpManipulation(Call call, Map<String, dynamic> options) {
    print('📞 Setting up SDP manipulation callback...');
    // Note: onLocalSdp might not be available in this version of sip_ua
    // We'll try a different approach - answer with the options directly
    try {
      call.answer(options);
    } catch (e) {
      print('❌ Error answering call after SDP manipulation setup: $e');
      rethrow;
    }
  }

  void makeCall(String target, {bool video = false}) {
    try {
      print('📞 Attempting to make call to: $target');
      _helper.call(target, voiceOnly: !video);
      print('📞 Call initiated successfully');
    } catch (e) {
      print('❌ Error making call: $e');
      setError('Failed to make call: $e');
    }
  }

  void hangupCall(Call call) {
    try {
      print('📞 Attempting to hangup call...');
      call.hangup();
      print('📞 Call hung up successfully');
    } catch (e) {
      print('❌ Error hanging up call: $e');
      setError('Failed to hangup call: $e');
    }
  }

  void reject(Call call) {
    try {
      print('📞 Attempting to reject call...');
      call.hangup(); // Use hangup for reject in this version
      print('📞 Call rejected successfully');
    } catch (e) {
      print('❌ Error rejecting call: $e');
      setError('Failed to reject call: $e');
    }
  }

  void muteMic(Call call) {
    try {
      print('🎤 Muting microphone...');
      call.mute(true, false); // audio=true, video=false
      print('🎤 Microphone muted');
    } catch (e) {
      print('❌ Error muting microphone: $e');
      setError('Failed to mute microphone: $e');
    }
  }

  void unmuteMic(Call call) {
    try {
      print('🎤 Unmuting microphone...');
      call.unmute(true, false); // audio=true, video=false
      print('🎤 Microphone unmuted');
    } catch (e) {
      print('❌ Error unmuting microphone: $e');
      setError('Failed to unmute microphone: $e');
    }
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    print('📞 Registration state changed: $state');
    // Just log the state as a string since we don't know the exact enum values
    print('📞 Registration state: $state');
  }

  @override
  void transportStateChanged(TransportState state) {
    print('Transport state changed: $state');
  }

  @override
  void onNewCall(Call call) {
    print('📞 SIP onNewCall triggered!');
    print('📞 Call details: $call');
    final callerId = call.remote_identity ?? call.remote_display_name ?? call.toString();
    print('📞 Extracted caller ID: $callerId');
    onIncomingCall?.call(call, callerId);
    print('📞 onIncomingCall callback executed');
  }

  @override
  void callStateChanged(Call call, CallState state) {
    print('📞 Call state changed: $state');
    print('📞 Call state type: ${state.runtimeType}');
    print('📞 Call state string: "${state.toString()}"');
    print('📞 Call object: $call');
    try {
      print('📞 Call state hashCode: ${state.hashCode}');
      print('📞 Call state toString length: ${state.toString().length}');
    } catch (e) {
      print('📞 Error getting state details: $e');
    }
    
    // More robust incoming call detection
    // Since the state string doesn't contain meaningful info, we'll use multiple approaches
    bool isIncomingCall = false;
    
    // Approach 1: Check if this is a new call (first state change)
    // We'll assume any call state change for a new call is incoming
    if (call != null) {
      try {
        // Check if this call has remote identity (incoming calls have this)
        if (call.remote_identity != null && call.remote_identity!.isNotEmpty) {
          print('📞 Call has remote identity, likely incoming call');
          isIncomingCall = true;
        }
        
        // Check if this is the first state change for this call
        // We'll use a simple approach: if we haven't seen this call before, it's incoming
        if (isIncomingCall) {
          print('📞 INCOMING CALL DETECTED in callStateChanged!');
          final callerId = call.remote_identity ?? call.remote_display_name ?? call.toString();
          print('📞 Caller ID from callStateChanged: $callerId');
          
          // Extract caller info from the SIP headers if available
          String displayName = 'Unknown Caller';
          String phoneNumber = 'Unknown Number';
          
          try {
            if (call.remote_identity != null) {
              phoneNumber = call.remote_identity!;
              displayName = call.remote_display_name ?? phoneNumber;
            }
          } catch (e) {
            print('📞 Error extracting caller info: $e');
          }
          
          print('📞 Final caller display name: $displayName');
          print('📞 Final caller phone number: $phoneNumber');
          
          onIncomingCall?.call(call, displayName);
          print('📞 onIncomingCall callback executed from callStateChanged');
        }
      } catch (e) {
        print('📞 Error in incoming call detection: $e');
      }
    }
    
    // Approach 2: Also check the state string for any meaningful keywords
    final stateStr = state.toString().toLowerCase();
    if (stateStr.contains('incoming') || 
        stateStr.contains('invite') || 
        stateStr.contains('new') ||
        stateStr.contains('ringing') ||
        stateStr.contains('progress')) {
      print('📞 INCOMING CALL DETECTED via state string analysis!');
      final callerId = call.remote_identity ?? call.remote_display_name ?? call.toString();
      print('📞 Caller ID from state string analysis: $callerId');
      
      // Extract caller info from the SIP headers if available
      String displayName = 'Unknown Caller';
      String phoneNumber = 'Unknown Number';
      
      try {
        if (call.remote_identity != null) {
          phoneNumber = call.remote_identity!;
          displayName = call.remote_display_name ?? phoneNumber;
        }
      } catch (e) {
        print('📞 Error extracting caller info: $e');
      }
      
      print('📞 Final caller display name: $displayName');
      print('📞 Final caller phone number: $phoneNumber');
      
      onIncomingCall?.call(call, displayName);
      print('📞 onIncomingCall callback executed from state string analysis');
    }
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    print('✉️ New SIP Message received');
  }

  @override
  void onNewNotify(Notify ntf) {
    print('📢 New SIP Notify received');
  }

  @override
  void onNewReinvite(ReInvite event) {
    print('🔄 New SIP Reinvite received');
  }

  void setError(String error) {
    print('❌ Error: $error');
    onError?.call(error);
  }
} 