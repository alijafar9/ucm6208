import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/simple_call_controller.dart';
import 'widgets/caller_id_text.dart';
import 'widgets/status_text.dart';
import 'widgets/recordings_panel.dart';

class SimpleCallScreen extends StatelessWidget {
  const SimpleCallScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SimpleCallController>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[50]!, Colors.purple[50]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.phone_in_talk,
                            color: Colors.blue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Simple Call',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(
                                'SIP Client for UCM6208',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'DEBUG',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Error Message
                  Obx(() => controller.errorMessage.isNotEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                controller.errorMessage.value,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink()),
                  
                  // Call Status
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (controller.hasIncomingCall.value)
                          Column(
                            children: [
                              CallerIdText(callerId: controller.callerId.value),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: controller.answerCall,
                                      icon: const Icon(Icons.call, size: 20),
                                      label: const Text('Answer'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: controller.rejectCall,
                                      icon: const Icon(Icons.call_end, size: 20),
                                      label: const Text('Decline'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else if (controller.inCall.value)
                          Column(
                            children: [
                              const StatusText(status: 'In call'),
                              const SizedBox(height: 16),
                              
                              // Recording status
                              Obx(() => controller.isRecording.value
                                ? Container(
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.red[200]!),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.fiber_manual_record, color: Colors.red, size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Recording in progress...',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                ),
                                              ),
                                              Obx(() => Text(
                                                'Duration: ${controller.recordingDuration.value.inSeconds}s',
                                                style: const TextStyle(color: Colors.red),
                                              )),
                                            ],
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: controller.stopCallRecording,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text('Stop'),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink()),
                              
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                alignment: WrapAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: controller.hangupCall,
                                    icon: const Icon(Icons.call_end, size: 20),
                                    label: const Text('Hang Up'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  Obx(() => ElevatedButton.icon(
                                    onPressed: controller.isMuted.value ? controller.unmuteCall : controller.muteCall,
                                    icon: Icon(controller.isMuted.value ? Icons.mic_off : Icons.mic, size: 20),
                                    label: Text(controller.isMuted.value ? 'Unmute' : 'Mute'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: controller.isMuted.value ? Colors.orange : Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  )),
                                  Obx(() => ElevatedButton.icon(
                                    onPressed: controller.isRecording.value ? controller.stopCallRecording : controller.startCallRecording,
                                    icon: Icon(controller.isRecording.value ? Icons.stop : Icons.fiber_manual_record, size: 20),
                                    label: Text(controller.isRecording.value ? 'Stop Recording' : 'Start Recording'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: controller.isRecording.value ? Colors.red : Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  )),
                                ],
                              ),
                            ],
                          )
                        else
                          const StatusText(status: 'No incoming call'),
                      ],
                    ),
                  ),
                  
                  // Microphone Test Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.mic, color: Colors.blue, size: 20),
                            ),
                            const SizedBox(width: 12),
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
                        const SizedBox(height: 16),
                        
                        // Status text
                        if (controller.microphoneTestStatus.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: controller.microphoneTestStatus.value.contains('✅') 
                                  ? Colors.green[50] 
                                  : controller.microphoneTestStatus.value.contains('❌') 
                                      ? Colors.red[50] 
                                      : Colors.orange[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: controller.microphoneTestStatus.value.contains('✅') 
                                    ? Colors.green[200]! 
                                    : controller.microphoneTestStatus.value.contains('❌') 
                                        ? Colors.red[200]! 
                                        : Colors.orange[200]!,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  controller.microphoneTestStatus.value.contains('✅') 
                                      ? Icons.check_circle 
                                      : controller.microphoneTestStatus.value.contains('❌') 
                                          ? Icons.error 
                                          : Icons.info,
                                  color: controller.microphoneTestStatus.value.contains('✅') 
                                      ? Colors.green 
                                      : controller.microphoneTestStatus.value.contains('❌') 
                                          ? Colors.red 
                                          : Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
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
                              ],
                            ),
                          ),
                        
                        // Test buttons
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: controller.testMicrophonePermission,
                              icon: const Icon(Icons.mic, size: 18),
                              label: const Text('Test Microphone'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: controller.listAudioDevices,
                              icon: const Icon(Icons.devices, size: 18),
                              label: const Text('List Devices'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: controller.playTestAudio,
                              icon: const Icon(Icons.volume_up, size: 18),
                              label: const Text('Test Audio'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Help button
                        Center(
                          child: TextButton.icon(
                            onPressed: controller.showMicrophoneHelp,
                            icon: const Icon(Icons.help_outline, size: 16),
                            label: const Text('Microphone Help'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue[600],
                            ),
                          ),
                        ),
                        
                        // Device dropdown
                        if (controller.audioInputDevices.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Audio Input Device',
                              border: OutlineInputBorder(),
                            ),
                            value: controller.selectedAudioInputId.value.isNotEmpty ?
                              controller.selectedAudioInputId.value : null,
                            items: controller.audioInputDevices.map((deviceId) => 
                              DropdownMenuItem<String>(
                                value: deviceId,
                                child: Text('Microphone ${deviceId.length > 8 ? deviceId.substring(0, 8) + '...' : deviceId}'),
                              )
                            ).toList(),
                            onChanged: (deviceId) {
                              if (deviceId != null) {
                                controller.selectAudioInput(deviceId);
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Outgoing call section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.call_made, color: Colors.purple, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Outgoing Call',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: (val) => controller.outgoingTarget.value = val,
                                decoration: InputDecoration(
                                  labelText: 'Call extension or SIP URI',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: controller.makeOutgoingCall,
                              icon: const Icon(Icons.call, size: 18),
                              label: const Text('Call'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Debug Tools Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.bug_report, color: Colors.orange, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Debug Tools',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: controller.testIncomingCallInterface,
                              icon: const Icon(Icons.science, size: 18),
                              label: const Text('Test Incoming Call'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: controller.checkWebRTCStatus,
                              icon: const Icon(Icons.bug_report, size: 18),
                              label: const Text('Check WebRTC'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: controller.toggleRecordingsPanel,
                              icon: const Icon(Icons.record_voice_over, size: 18),
                              label: const Text('Recordings'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Recordings Panel
                  Obx(() => controller.showRecordingsPanel.value
                    ? RecordingsPanel(controller: controller)
                    : const SizedBox.shrink()),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 