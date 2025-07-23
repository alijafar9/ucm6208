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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: controller.answerCall,
                        child: const Text('Answer'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: controller.rejectCall,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Reject'),
                      ),
                    ],
                  ),
                ],
              )
            else if (controller.inCall.value)
              Column(
                children: [
                  StatusText(status: 'In call'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: controller.hangupCall,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Hang Up'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: controller.isMuted.value ? controller.unmuteCall : controller.muteCall,
                        child: Text(controller.isMuted.value ? 'Unmute' : 'Mute'),
                      ),
                    ],
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
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 180,
                  child: TextField(
                    onChanged: (val) => controller.outgoingTarget.value = val,
                    decoration: const InputDecoration(
                      labelText: 'Call extension or SIP URI',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: controller.makeOutgoingCall,
                  child: const Text('Call'),
                ),
              ],
            ),
          ],
        )),
      ),
    );
  }
} 