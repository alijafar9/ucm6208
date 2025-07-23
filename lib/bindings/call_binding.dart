import 'package:get/get.dart';
import '../controllers/simple_call_controller.dart';

class CallBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SimpleCallController>(() => SimpleCallController());
  }
} 