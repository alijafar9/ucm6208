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
      body: SingleChildScrollView(
        child: Center(
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
                // Incoming call card design
                Container(
                  width: 320,
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Phone icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.phone,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Caller name
                      Text(
                        controller.callerId.value.isNotEmpty 
                            ? controller.callerId.value 
                            : 'Unknown Caller',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      
                      // Caller number
                      Text(
                        controller.callerId.value.isNotEmpty 
                            ? controller.callerId.value 
                            : 'No number',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      
                      // Registered client badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green[600],
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Registered Client',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Answer and Decline buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Decline button
                          Expanded(
                            child: Container(
                              height: 56,
                              margin: const EdgeInsets.only(right: 4),
                              child: ElevatedButton(
                                onPressed: controller.rejectCall,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.call_end, size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Decline',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // Answer button
                          Expanded(
                            child: Container(
                              height: 56,
                              margin: const EdgeInsets.only(left: 4),
                              child: ElevatedButton(
                                onPressed: controller.answerCall,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.call, size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Answer',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
              
              const SizedBox(height: 20),
              
              // Microphone Test Section
              Container(
                width: 400,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.mic, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Microphone Test',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Status text
                    if (controller.microphoneTestStatus.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: controller.microphoneTestStatus.value.contains('✅') 
                              ? Colors.green[100] 
                              : controller.microphoneTestStatus.value.contains('❌') 
                                  ? Colors.red[100] 
                                  : Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          controller.microphoneTestStatus.value,
                          style: TextStyle(
                            color: controller.microphoneTestStatus.value.contains('✅') 
                                ? Colors.green[800] 
                                : controller.microphoneTestStatus.value.contains('❌') 
                                    ? Colors.red[800] 
                                    : Colors.orange[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    
                    // Microphone test buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: controller.testMicrophonePermission,
                          icon: const Icon(Icons.mic, size: 16),
                          label: const Text('Test Microphone'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: controller.listAudioDevices,
                          icon: const Icon(Icons.computer, size: 16),
                          label: const Text('List Devices'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: controller.testAudioOutput,
                          icon: const Icon(Icons.volume_up, size: 16),
                          label: const Text('Test Audio'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Help button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: controller.showMicrophoneHelp,
                          icon: const Icon(Icons.help_outline, size: 16),
                          label: const Text('Microphone Help'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Device dropdown
                    if (controller.audioInputDevices.isNotEmpty)
                      DropdownButton<String>(
                        value: controller.selectedAudioInputId.value.isNotEmpty ? controller.selectedAudioInputId.value : null,
                        hint: const Text('Select Microphone'),
                        isExpanded: true,
                        items: controller.audioInputDevices.map((device) => DropdownMenuItem(
                          value: device.deviceId,
                          child: Text(device.label ?? 'Unknown Mic'),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) controller.selectAudioInput(val);
                        },
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Outgoing call section
              Container(
                width: 400,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Outgoing Call',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
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
                ),
              ),
              
              // Test button for incoming call interface
              Container(
                width: 400,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Debug Tools',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: controller.testIncomingCallInterface,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('🧪 Test Incoming Call Interface'),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          )),
        ),
      ),
    );
  }
} 