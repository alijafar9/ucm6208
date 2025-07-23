import 'package:get/get.dart';
import '../services/sip_service.dart';
import 'package:sip_ua/sip_ua.dart';

class SimpleCallController extends GetxController {
  final SipService sipService = SipService();

  var callerId = ''.obs;
  var hasIncomingCall = false.obs;
  var outgoingTarget = ''.obs;
  var inCall = false.obs;
  var isMuted = false.obs;
  Call? currentCall;

  @override
  void onInit() {
    super.onInit();
    sipService.onIncomingCall = (call, id) {
      currentCall = call;
      callerId.value = id;
      hasIncomingCall.value = true;
    };
  }

  void register() {
    sipService.register(
      username: 'YOUR_EXTENSION',
      password: 'YOUR_PASSWORD',
      domain: 'YOUR_UCM_IP',
      wsUri: 'wss://YOUR_UCM_IP:8089/ws',
    );
  }

  void answerCall() {
    if (currentCall != null) {
      sipService.answer(currentCall!);
      inCall.value = true;
      hasIncomingCall.value = false;
    }
  }

  void rejectCall() {
    if (currentCall != null) {
      sipService.reject(currentCall!);
      _resetCallState();
    }
  }

  void makeOutgoingCall() {
    if (outgoingTarget.value.isNotEmpty) {
      sipService.makeCall(outgoingTarget.value);
      inCall.value = true;
    }
  }

  void hangupCall() {
    if (currentCall != null) {
      sipService.hangup(currentCall!);
      _resetCallState();
      inCall.value = false;
    }
  }

  void muteCall() {
    if (currentCall != null) {
      sipService.mute(currentCall!);
      isMuted.value = true;
    }
  }

  void unmuteCall() {
    if (currentCall != null) {
      sipService.unmute(currentCall!);
      isMuted.value = false;
    }
  }

  void _resetCallState() {
    hasIncomingCall.value = false;
    callerId.value = '';
    currentCall = null;
    inCall.value = false;
    isMuted.value = false;
  }
} 