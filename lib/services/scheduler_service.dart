import 'package:flutter/material.dart';
import 'logger_service.dart';

enum SimulationMode { instant, realistic, sessionBased }

class SchedulerService {
  final LoggerService _logger = LoggerService();
  final Random _random = Random();

  bool isCurrentlyInActiveHours(TimeOfDay start, TimeOfDay end) {
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
  }

  Duration calculateNextDelay(SimulationMode mode, {int? baseDelayMinutes}) {
    if (mode == SimulationMode.instant) {
      return Duration(seconds: _random.nextInt(10) + 5);
    }

    if (mode == SimulationMode.realistic) {
      // If outside active hours, delay is much longer
      if (!isCurrentlyInActiveHours()) {
        _logger.log('Outside active hours. Simulating downtime...', type: LogType.info);
        return Duration(hours: _random.nextInt(4) + 2);
      }
      
      // Random delay between 30 and 120 minutes
      final minutes = _random.nextInt(90) + 30;
      return Duration(minutes: minutes);
    }

    // Session based usually has a set frequency
    final base = baseDelayMinutes ?? 60;
    return Duration(minutes: base + _random.nextInt(15));
  }

  int calculateSessionCommitCount(SimulationMode mode, int remainingTarget) {
    if (mode == SimulationMode.instant) {
      // For instant mode, try to finish the remaining target in one pulse session
      return remainingTarget;
    }
    
    // For realistic mode, 2 to 5 commits per session is realistic
    return _random.nextInt(4) + 2;
  }
}
