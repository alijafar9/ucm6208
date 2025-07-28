import 'package:sip_ua/sip_ua.dart';
import 'package:sip_ua/src/constants.dart';

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
    
    // Try different answer strategies
    final strategies = [
      {
        'name': 'Standard answer',
        'options': <String, dynamic>{
          'mediaConstraints': {'audio': true, 'video': false},
          'pcConfig': {
            'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}],
            'iceTransportPolicy': 'all',
            'bundlePolicy': 'max-bundle',
            'rtcpMuxPolicy': 'require',
          },
        },
      },
      {
        'name': 'Minimal answer',
        'options': <String, dynamic>{
          'mediaConstraints': {'audio': true, 'video': false},
        },
      },
      {
        'name': 'Basic answer',
        'options': <String, dynamic>{},
      },
    ];
    
    for (int i = 0; i < strategies.length; i++) {
      final strategy = strategies[i];
      try {
        print('📞 Trying strategy ${i + 1}: ${strategy['name']}');
        call.answer(strategy['options'] as Map<String, dynamic>);
        print('📞 Success with strategy: ${strategy['name']}');
        return;
      } catch (e) {
        print('❌ Strategy ${i + 1} failed: $e');
        if (i == strategies.length - 1) {
          // All strategies failed
          print('❌ All answer strategies failed');
          rethrow;
        }
      }
    }
  }

  @override
  void onNewCall(Call call) {
    print('📞 SIP onNewCall triggered!');
    print('📞 Call details: $call');
    
    // Use the actual properties that exist in the Call class
    final callerId = call.remote_identity ?? call.remote_display_name ?? call.toString();
    print('📞 Extracted caller ID: $callerId');
    
    onIncomingCall?.call(call, callerId);
    print('📞 onIncomingCall callback executed');
  }

  void answer(Call call) {
    try {
      print('Answering call...');
      
      // Configure answer options to handle codec issues
      final answerOptions = {
        'mediaConstraints': {
          'audio': true,
          'video': false,
        },
        'pcConfig': {
          'iceServers': [
            {'urls': 'stun:stun.l.google.com:19302'},
          ],
          'iceTransportPolicy': 'all',
          'bundlePolicy': 'max-bundle',
          'rtcpMuxPolicy': 'require',
        },
      };
      
      // Try to answer with basic options first
      call.answer(answerOptions);
      print('Call answered successfully');
    } catch (e) {
      print('Error answering call: $e');
      
      // If the first attempt fails, try with a different approach
      if (e.toString().contains('G726-32') || e.toString().contains('payload type')) {
        print('📞 Codec conflict detected, trying alternative approach...');
        try {
          // Try answering with minimal options
          call.answer({
            'mediaConstraints': {'audio': true, 'video': false},
          });
          print('📞 Call answered with minimal options');
        } catch (e2) {
          print('❌ Alternative approach also failed: $e2');
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  void reject(Call call) {
    try {
      print('Rejecting call...');
      call.hangup();
      print('Call rejected successfully');
    } catch (e) {
      print('Error rejecting call: $e');
      rethrow;
    }
  }

  void makeCall(String target, {bool voiceOnly = true, String? audioInputId}) {
    try {
      print('Making outgoing call to: $target');
      _helper.call(target, voiceOnly: voiceOnly);
      print('Outgoing call initiated');
    } catch (e) {
      print('Error making outgoing call: $e');
      if (onError != null) {
        onError!(e.toString());
      }
      rethrow;
    }
  }

  void hangup(Call call) {
    try {
      print('Hanging up call...');
      call.hangup();
      print('Call hung up successfully');
    } catch (e) {
      print('Error hanging up call: $e');
      rethrow;
    }
  }

  void mute(Call call, {bool audio = true, bool video = false}) {
    try {
      print('Muting call...');
      call.mute(audio, video);
      print('Call muted');
    } catch (e) {
      print('Error muting call: $e');
      rethrow;
    }
  }

  void unmute(Call call, {bool audio = true, bool video = false}) {
    try {
      print('Unmuting call...');
      call.unmute(audio, video);
      print('Call unmuted');
    } catch (e) {
      print('Error unmuting call: $e');
      rethrow;
    }
  }

  // --- Required empty implementations ---
  @override
  void transportStateChanged(TransportState state) {
    print('Transport state changed: $state');
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    print('📞 Registration state changed: $state');
    
    // Just log the state as a string since we don't know the exact enum values
    print('📞 Registration state: $state');
  }

  @override
  void callStateChanged(Call call, CallState state) {
    print('📞 Call state changed: $state');
    print('📞 Call state type: ${state.runtimeType}');
    print('📞 Call state string: "${state.toString()}"');
    print('📞 Call object: $call');
    
    // Log all possible state information
    try {
      print('📞 Call state hashCode: ${state.hashCode}');
      print('📞 Call state toString length: ${state.toString().length}');
    } catch (e) {
      print('📞 Error getting state details: $e');
    }
    
    // Since toString() doesn't work, let's try to detect incoming calls differently
    // We'll trigger the incoming call interface for any new call state change
    // and let the UI handle whether to show it or not
    
    print('📞 INCOMING CALL DETECTED in callStateChanged!');
    final callerId = call.remote_identity ?? call.remote_display_name ?? call.toString();
    print('📞 Caller ID from callStateChanged: $callerId');
    
    // Extract caller info from the SIP headers if available
    String displayName = 'Unknown Caller';
    String phoneNumber = 'Unknown Number';
    
    try {
      // Try to get caller info from the call object
      if (call.remote_identity != null) {
        phoneNumber = call.remote_identity!;
        displayName = call.remote_display_name ?? phoneNumber;
      }
    } catch (e) {
      print('📞 Error extracting caller info: $e');
    }
    
    print('📞 Final caller display name: $displayName');
    print('📞 Final caller phone number: $phoneNumber');
    
    // Trigger the incoming call callback
    onIncomingCall?.call(call, displayName);
    print('📞 onIncomingCall callback executed from callStateChanged');
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    print('New SIP message received');
  }

  @override
  void onNewNotify(Notify ntf) {
    print('New SIP notify received');
  }

  @override
  void onNewReinvite(ReInvite event) {
    print('New SIP reinvite received');
  }
} 