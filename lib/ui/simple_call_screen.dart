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
            if (controller.errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                color: Colors.red[100],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Flexible(child: Text(controller.errorMessage.value, style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),
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
            DropdownButton<String>(
              value: controller.selectedAudioInputId.value.isNotEmpty ? controller.selectedAudioInputId.value : null,
              hint: const Text('Select Microphone'),
              items: controller.audioInputDevices.map((device) => DropdownMenuItem(
                value: device.deviceId,
                child: Text(device.label ?? 'Unknown Mic'),
              )).toList(),
              onChanged: (val) {
                if (val != null) controller.selectAudioInput(val);
              },
            ),
            const SizedBox(height: 16),
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