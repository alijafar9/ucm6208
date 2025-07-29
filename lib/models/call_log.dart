class CallLog {
  final String id;
  final String callerId;
  final DateTime timestamp;
  final Duration duration;
  final String type; // 'incoming', 'outgoing', 'missed'

  CallLog({
    required this.id,
    required this.callerId,
    required this.timestamp,
    required this.duration,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'callerId': callerId,
    'timestamp': timestamp.toIso8601String(),
    'duration': duration.inSeconds,
    'type': type,
  };

  factory CallLog.fromJson(Map<String, dynamic> json) => CallLog(
    id: json['id'],
    callerId: json['callerId'],
    timestamp: DateTime.parse(json['timestamp']),
    duration: Duration(seconds: json['duration']),
    type: json['type'],
  );
}

class CallRecording {
  final String id;
  final String callerId;
  final DateTime timestamp;
  final Duration duration;
  final String fileName;
  final String status; // 'recording', 'completed', 'failed'
  final String? audioData; // Base64 encoded audio data

  CallRecording({
    required this.id,
    required this.callerId,
    required this.timestamp,
    required this.duration,
    required this.fileName,
    required this.status,
    this.audioData,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'callerId': callerId,
    'timestamp': timestamp.toIso8601String(),
    'duration': duration.inSeconds,
    'fileName': fileName,
    'status': status,
    'audioData': audioData,
  };

  factory CallRecording.fromJson(Map<String, dynamic> json) => CallRecording(
    id: json['id'],
    callerId: json['callerId'],
    timestamp: DateTime.parse(json['timestamp']),
    duration: Duration(seconds: json['duration']),
    fileName: json['fileName'],
    status: json['status'],
    audioData: json['audioData'],
  );
} 