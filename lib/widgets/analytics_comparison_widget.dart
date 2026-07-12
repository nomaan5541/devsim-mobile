import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnalyticsComparisonWidget extends StatelessWidget {
  final Map<String, int> localHistory;
  final List<List<Map<String, dynamic>>>? githubWeeks;
  final int currentStreak;

  const AnalyticsComparisonWidget({
    super.key,
    required this.localHistory,
    required this.githubWeeks,
    required this.currentStreak,
  });

  int _getRealCount(String dateStr) {
    if (githubWeeks == null) return 0;
    for (var week in githubWeeks!) {
      for (var day in week) {
        if (day['date'] == dateStr) {
          return day['count'] as int? ?? 0;
        }
      }
    }
    return 0;
  }

  String _getStreakForecast() {
    final milestones = [7, 21, 30, 100, 250, 500];
    for (var m in milestones) {
      if (currentStreak < m) {
        final diff = m - currentStreak;
        return "$diff days remaining to unlock the '$m Days' milestone badge!";
      }
    }
    return "All milestone badges unlocked! Truly legendary.";
  }

  @override
  Widget build(BuildContext context) {
    // Generate dates for the last 7 days
    final now = DateTime.now();
    final List<DateTime> last7Days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LOCAL VS. REAL-WORLD ANALYTICS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.white60,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Last 7 Days Activity',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    ),
                    Row(
                      children: [
                        _LegendItem(color: Color(0xFF6366F1), label: 'Simulated'),
                        SizedBox(width: 12),
                        _LegendItem(color: Color(0xFF10B981), label: 'Actual'),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 20),
                ...last7Days.map((date) {
                  final dateStr = DateFormat('yyyy-MM-dd').format(date);
                  final label = DateFormat('E, MMM d').format(date);
                  
                  final simulatedCount = localHistory[dateStr] ?? 0;
                  final realCount = _getRealCount(dateStr);
                  
                  final maxCount = [simulatedCount, realCount, 1].reduce((a, b) => a > b ? a : b).toDouble();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
                        const SizedBox(height: 4),
                        // Simulated Bar
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: simulatedCount / maxCount,
                                  backgroundColor: Colors.white.withOpacity(0.02),
                                  color: const Color(0xFF6366F1),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 16,
                              child: Text(
                                '$simulatedCount',
                                style: const TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Real-World Bar
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: realCount / maxCount,
                                  backgroundColor: Colors.white.withOpacity(0.02),
                                  color: const Color(0xFF10B981),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 16,
                              child: Text(
                                '$realCount',
                                style: const TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 24, color: Colors.white10),
                const Text(
                  'STREAK FORECASTER',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white38, letterSpacing: 1.0),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _getStreakForecast(),
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60)),
      ],
    );
  }
}
