import 'package:get/get.dart';
import '../services/sip_service.dart';
import 'package:sip_ua/sip_ua.dart';

class SimpleCallController extends GetxController {
  final SipService sipService = SipService();

  var callerId = ''.obs;
  var hasIncomingCall = false.obs;
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
      hasIncomingCall.value = false;
      callerId.value = '';
      currentCall = null;
    }
  }
} 