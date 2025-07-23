import 'package:get/get.dart';
import '../services/sip_service.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

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
  Call? currentCall;

  @override
  void onInit() {
    super.onInit();
    sipService.onIncomingCall = (call, id) {
      print('🔄 Incoming call detected in controller!');
      print('Caller ID: $id');
      print('Call object: $call');
      currentCall = call;
      callerId.value = id;
      hasIncomingCall.value = true;
      print('✅ hasIncomingCall set to: ${hasIncomingCall.value}');
      print('✅ callerId set to: ${callerId.value}');
    };
    sipService.onError = setError;
    enumerateAudioInputDevices();
    register(); // Auto-register on startup
  }

  Future<void> enumerateAudioInputDevices() async {
    try {
      final devices = await webrtc.navigator.mediaDevices.enumerateDevices();
      audioInputDevices.value = devices.where((d) => d.kind == 'audioinput').toList();
      if (audioInputDevices.isNotEmpty && selectedAudioInputId.value.isEmpty) {
        selectedAudioInputId.value = audioInputDevices.first.deviceId ?? '';
      }
    } catch (e) {
      setError('Failed to enumerate audio devices: $e');
    }
  }

  void selectAudioInput(String deviceId) {
    selectedAudioInputId.value = deviceId;
  }

  void register() {
    sipService.register(
      username: '002',
      password: 'tr123',
      domain: '172.16.26.2',
      wsUri: 'ws://172.16.26.2:8088/ws',
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
} 