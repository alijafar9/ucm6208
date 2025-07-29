import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/simple_call_controller.dart';

class RecordingsPanel extends StatelessWidget {
  final SimpleCallController controller;

  const RecordingsPanel({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple[200]!),
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
                child: const Icon(Icons.record_voice_over, color: Colors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Call Recordings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ),
              IconButton(
                onPressed: controller.toggleRecordingsPanel,
                icon: const Icon(Icons.close),
                tooltip: 'Close',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Recording status
          if (controller.isRecording.value)
            Container(
              width: double.infinity,
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
            ),
          
          // Recordings list
          Obx(() {
            if (controller.callRecordings.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.record_voice_over,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No recordings yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start a call to record audio for debugging',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.list,
                      color: Colors.purple[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${controller.callRecordings.length} recording(s)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.purple[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...controller.callRecordings.map((recording) => _buildRecordingItem(recording)),
              ],
            );
          }),
          
          const SizedBox(height: 16),
          
          // Manual recording controls
          if (controller.inCall.value && !controller.isRecording.value)
            Center(
              child: ElevatedButton.icon(
                onPressed: controller.startCallRecording,
                icon: const Icon(Icons.fiber_manual_record, size: 18),
                label: const Text('Start Recording'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildRecordingItem(CallRecording recording) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: recording.status == 'completed' ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              recording.status == 'completed' ? Icons.check_circle : Icons.error,
              color: recording.status == 'completed' ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Call with ${recording.callerId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${recording.duration.inSeconds}s • ${_formatTimestamp(recording.timestamp)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => controller.deleteRecording(recording.id),
            icon: const Icon(Icons.delete, size: 18),
            tooltip: 'Delete recording',
            style: IconButton.styleFrom(
              backgroundColor: Colors.red[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 