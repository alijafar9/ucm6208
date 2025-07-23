import 'package:sip_ua/sip_ua.dart';
import 'package:sip_ua/src/constants.dart';

class SipService extends SipUaHelperListener {
  final SIPUAHelper _helper = SIPUAHelper();
  Function(Call, String)? onIncomingCall;

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

  @override
  void onNewCall(Call call) {
    print('New call received: ${call.toString()}');
    // Use the actual properties that exist in the Call class
    final callerId = call.remote_identity ?? call.remote_display_name ?? call.toString();
    onIncomingCall?.call(call, callerId);
  }

  void answer(Call call) {
    try {
      print('Answering call...');
      call.answer({});
      print('Call answered successfully');
    } catch (e) {
      print('Error answering call: $e');
      rethrow;
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

  void makeCall(String target, {bool voiceOnly = true}) {
    try {
      print('Making outgoing call to: $target');
      _helper.call(target, voiceOnly: voiceOnly);
      print('Outgoing call initiated');
    } catch (e) {
      print('Error making outgoing call: $e');
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
    print('Registration state changed: $state');
  }

  @override
  void callStateChanged(Call call, CallState state) {
    print('Call state changed: $state');
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