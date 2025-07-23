import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/simple_call_controller.dart';
import 'widgets/caller_id_text.dart';
import 'widgets/status_text.dart';

class SimpleCallScreen extends StatelessWidget {
  const SimpleCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SimpleCallController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Simple Call')),
      body: Center(
        child: Obx(() => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (controller.hasIncomingCall.value)
              Column(
                children: [
                  CallerIdText(callerId: controller.callerId.value),
                  const SizedBox(height: 16),
                  StatusText(status: 'Incoming call...'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.answerCall,
                    child: const Text('Answer'),
                  ),
                ],
              )
            else
              const StatusText(status: 'No incoming call'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: controller.register,
              child: const Text('Register SIP'),
            ),
          ],
        )),
      ),
    );
  }
} 