import 'package:sip_ua/sip_ua.dart';

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
    UaSettings settings = UaSettings();
    settings.webSocketUrl = wsUri;
    settings.webSocketSettings.extraHeaders = {};
    settings.uri = 'sip:$username@$domain';
    settings.authorizationUser = username;
    settings.password = password;
    settings.displayName = displayName ?? username;
    settings.userAgent = 'Dart SIP Client';
    _helper.start(settings);
  }

  @override
  void onNewCall(Call call) {
    final callerId = call.toString();
    onIncomingCall?.call(call, callerId);
  }

  void answer(Call call) {
    call.answer({});
  }

  // --- Required empty implementations ---
  @override
  void transportStateChanged(TransportState state) {}

  @override
  void registrationStateChanged(RegistrationState state) {}

  @override
  void callStateChanged(Call call, CallState state) {}

  @override
  void onNewMessage(SIPMessageRequest msg) {}

  @override
  void onNewNotify(Notify ntf) {}

  @override
  void onNewReinvite(ReInvite event) {}
} 