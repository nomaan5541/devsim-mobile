import 'package:flutter/foundation.dart';

class CommitRecord {
  final String path;
  final String message;
  final DateTime timestamp;
  final bool isSuccess;

  CommitRecord({
    required this.path,
    required this.message,
    required this.timestamp,
    required this.isSuccess,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'isSuccess': isSuccess,
  };

  factory CommitRecord.fromJson(Map<String, dynamic> json) => CommitRecord(
    path: json['path'],
    message: json['message'],
    timestamp: DateTime.parse(json['timestamp']),
    isSuccess: json['isSuccess'],
  );
}
