import 'package:get/get.dart';
import '../controllers/simple_call_controller.dart';
import '../services/sip_service.dart';

class CallBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SipService>(() => SipService());
    Get.lazyPut<SimpleCallController>(() => SimpleCallController());
  }
} 