import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/logger_service.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pulse Logs', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () {}),
        ],
      ),
      body: StreamBuilder<List<AppLog>>(
        stream: LoggerService().logStream,
        initialData: LoggerService().currentLogs,
        builder: (context, snapshot) {
          final logs = snapshot.data ?? [];
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF000000),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: ListView.separated(
              itemCount: logs.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withOpacity(0.05)),
              itemBuilder: (context, index) {
                final log = logs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('HH:mm:ss').format(log.timestamp),
                        style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          log.message,
                          style: TextStyle(
                            color: _getLogColor(log.type),
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getLogColor(LogType type) {
    switch (type) {
      case LogType.error:
        return Colors.redAccent;
      case LogType.warning:
        return Colors.orangeAccent;
      case LogType.success:
        return Colors.greenAccent;
      case LogType.api:
        return Colors.blueAccent;
      default:
        return Colors.white70;
    }
  }
}
