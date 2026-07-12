import 'dart:math';
import 'package:flutter/material.dart';
import 'logger_service.dart';

enum SimulationMode { instant, realistic, sessionBased }
enum BehaviorProfile { nightOwl, steady9to5, weekendWarrior, standard }

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

  Duration calculateNextDelay(
    SimulationMode mode,
    TimeOfDay startTime,
    TimeOfDay endTime, {
    int? baseDelayMinutes,
    BehaviorProfile profile = BehaviorProfile.standard,
  }) {
    if (mode == SimulationMode.instant) {
      return Duration(seconds: _random.nextInt(10) + 5);
    }

    final now = DateTime.now();
    bool isDowntime = false;

    // Check active hours based on profile
    if (mode == SimulationMode.realistic) {
      if (profile == BehaviorProfile.nightOwl) {
        // Night Owl: Active 8 PM (20:00) to 4 AM (04:00)
        final hour = now.hour;
        if (hour > 4 && hour < 20) {
          isDowntime = true;
          _logger.log('[Scheduler] Night Owl Profile: Daytime downtime. Sleep mode active.', type: LogType.info);
        }
      } else if (profile == BehaviorProfile.steady9to5) {
        // Steady 9-to-5: Active 9 AM (09:00) to 5 PM (17:00)
        final hour = now.hour;
        if (hour < 9 || hour >= 17) {
          isDowntime = true;
          _logger.log('[Scheduler] 9-to-5 Profile: After hours downtime. Offline mode active.', type: LogType.info);
        }
      } else if (profile == BehaviorProfile.weekendWarrior) {
        // Weekend Warrior: Active Saturday & Sunday. Weekdays are downtime.
        final weekday = now.weekday;
        if (weekday >= 1 && weekday <= 5) {
          isDowntime = true;
          _logger.log('[Scheduler] Weekend Warrior Profile: Weekday downtime. Commits paused.', type: LogType.info);
        }
      } else {
        // Standard profile: respects user start and end times
        if (!isCurrentlyInActiveHours(startTime, endTime)) {
          isDowntime = true;
          _logger.log('[Scheduler] Standard Profile: Outside active hours. Offline mode active.', type: LogType.info);
        }
      }

      if (isDowntime) {
        // Return a long sleep window (e.g. 2 to 6 hours)
        final downtimeHours = _random.nextInt(4) + 2;
        return Duration(hours: downtimeHours);
      }

      // Inject simulated "Noise" (breaks, meetings) - 15% chance during active hours
      if (_random.nextDouble() < 0.15) {
        final noiseType = _random.nextInt(3);
        if (noiseType == 0) {
          _logger.log('[Simulator] Injecting noise: Pausing 45m for simulated standup meeting.', type: LogType.info);
          return const Duration(minutes: 45);
        } else if (noiseType == 1) {
          _logger.log('[Simulator] Injecting noise: Pausing 1h 15m for lunch break.', type: LogType.info);
          return const Duration(minutes: 75);
        } else {
          _logger.log('[Simulator] Injecting noise: Pausing 30m for coffee break.', type: LogType.info);
          return const Duration(minutes: 30);
        }
      }

      // Standard active delay between 30 and 120 minutes
      final minutes = _random.nextInt(90) + 30;
      return Duration(minutes: minutes);
    }

    // Session based usually has a set frequency
    final base = baseDelayMinutes ?? 60;
    
    // Inject break noise in session-based occasionally as well
    if (_random.nextDouble() < 0.10) {
      _logger.log('[Simulator] Injecting session break noise: Adding 20m buffer.', type: LogType.info);
      return Duration(minutes: base + 20 + _random.nextInt(10));
    }
    
    return Duration(minutes: base + _random.nextInt(15));
  }

  int calculateSessionCommitCount(SimulationMode mode, int remainingTarget) {
    if (mode == SimulationMode.instant) {
      return remainingTarget;
    }
    
    return _random.nextInt(4) + 2;
  }

  List<DateTime> calculateScheduledTimesForDay({
    required int commitsCount,
    required TimeOfDay start,
    required TimeOfDay end,
    DateTime? relativeTo,
  }) {
    final baseDate = relativeTo ?? DateTime.now();
    final List<DateTime> slots = [];
    if (commitsCount <= 0) return slots;

    final startDt = DateTime(baseDate.year, baseDate.month, baseDate.day, start.hour, start.minute);
    var endDt = DateTime(baseDate.year, baseDate.month, baseDate.day, end.hour, end.minute);

    if (startDt.isAfter(endDt) || startDt.isAtSameMomentAs(endDt)) {
      endDt = endDt.add(const Duration(days: 1));
    }

    final totalMinutes = endDt.difference(startDt).inMinutes;
    if (totalMinutes <= 0) return slots;

    if (commitsCount == 1) {
      slots.add(startDt.add(Duration(minutes: totalMinutes ~/ 2)));
    } else {
      final interval = totalMinutes / (commitsCount - 1);
      for (int i = 0; i < commitsCount; i++) {
        slots.add(startDt.add(Duration(minutes: (interval * i).round())));
      }
    }

    return slots;
  }

  DateTime? getNextUpcomingSlot(List<DateTime> slots, DateTime now) {
    for (var slot in slots) {
      if (slot.isAfter(now)) {
        return slot;
      }
    }
    return null;
  }
}
