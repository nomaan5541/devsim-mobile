import 'dart:async';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LogType { info, success, warning, error, api }

class AppLog {
  final DateTime timestamp;
  final String message;
  final LogType type;

  AppLog({required this.timestamp, required this.message, required this.type});

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'message': message,
        'type': type.index,
      };
}

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  final _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, errorMethodCount: 5, lineLength: 50, colors: true, printEmojis: true),
  );

  final List<AppLog> _logs = [];
  final _logStreamController = StreamController<List<AppLog>>.broadcast();

  Stream<List<AppLog>> get logStream => _logStreamController.stream;
  List<AppLog> get currentLogs => List.unmodifiable(_logs);

  void log(String message, {LogType type = LogType.info}) {
    final entry = AppLog(timestamp: DateTime.now(), message: message, type: type);
    _logs.insert(0, entry);
    if (_logs.length > 500) _logs.removeLast(); // Keep reasonable history
    
    _logStreamController.add(_logs);

    switch (type) {
      case LogType.error:
        _logger.e(message);
        break;
      case LogType.warning:
        _logger.w(message);
        break;
      case LogType.success:
        _logger.i('✅ $message');
        break;
      case LogType.api:
        _logger.d('🌐 $message');
        break;
      default:
        _logger.i(message);
    }
    
    _persistLog(entry);
  }

  Future<void> _persistLog(AppLog entry) async {
    // For simplicity without SQLite yet, we'll use a revolving list in SharedPreferences
    // or just let it stay in memory for now. 
    // In a full prod app, this would write to a local file/DB.
  }
}
