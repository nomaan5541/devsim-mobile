import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/app_provider.dart';

class GraphPlannerCard extends StatefulWidget {
  final AppProvider provider;

  const GraphPlannerCard({super.key, required this.provider});

  @override
  State<GraphPlannerCard> createState() => _GraphPlannerCardState();
}

class _GraphPlannerCardState extends State<GraphPlannerCard> {
  int _selectedDays = 14;
  double _commitsPerDay = 3.0;

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return "0s";
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return "${hours}h ${minutes}m ${seconds}s";
    } else if (minutes > 0) {
      return "${minutes}m ${seconds}s";
    }
    return "${seconds}s";
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FUTURE GRAPH PLANNER',
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
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: provider.isPlanActive
                  ? _buildActivePlanView(provider)
                  : _buildSetupPlanView(provider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSetupPlanView(AppProvider provider) {
    final totalCommits = _selectedDays * _commitsPerDay.toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule Daily Target Syncs',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        const SizedBox(height: 6),
        const Text(
          'Configure a systematic future schedule to automatically fill your GitHub contribution graph with realistic commits.',
          style: TextStyle(fontSize: 12, color: Colors.white60),
        ),
        const SizedBox(height: 20),
        // Days Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Plan Duration:', style: TextStyle(fontSize: 13, color: Colors.white70)),
            DropdownButton<int>(
              value: _selectedDays,
              dropdownColor: const Color(0xFF1E1B4B),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 7, child: Text('7 Days')),
                DropdownMenuItem(value: 14, child: Text('14 Days')),
                DropdownMenuItem(value: 30, child: Text('30 Days')),
                DropdownMenuItem(value: 100, child: Text('100 Days')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedDays = val;
                  });
                }
              },
            ),
          ],
        ),
        const Divider(height: 20, color: Colors.white10),
        // Commits Per Day
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Commits Per Day:', style: TextStyle(fontSize: 13, color: Colors.white70)),
                Text(
                  '${_commitsPerDay.toInt()}',
                  style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            Slider(
              value: _commitsPerDay,
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: const Color(0xFF6366F1),
              inactiveColor: Colors.white10,
              onChanged: (v) {
                setState(() {
                  _commitsPerDay = v;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Summary Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blueAccent, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'This plan will push a total of $totalCommits commits ($totalCommits daily fills) over $_selectedDays days, spaced evenly during working hours.',
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              provider.startGraphPlan(_selectedDays, _commitsPerDay.toInt());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              'Start Graph Planner Mode',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildActivePlanView(AppProvider provider) {
    final totalCommits = provider.planDays * provider.planCommitsPerDay;
    final progress = totalCommits > 0 ? provider.planCompletedCommits / totalCommits : 0.0;

    final now = DateTime.now();
    final timeUntilNext = provider.nextScheduledCommitTime != null
        ? provider.nextScheduledCommitTime!.difference(now)
        : Duration.zero;

    final daysRemaining = provider.planEndTime != null
        ? provider.planEndTime!.difference(now).inDays + 1
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${provider.planDays}-Day Graph Filler Plan'.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white38, letterSpacing: 1.0),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Plan Status: Syncing...',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${provider.planCommitsPerDay} commits/day',
                style: const TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
        const SizedBox(height: 20),
        // Progress Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Fills Succeeded:', style: TextStyle(fontSize: 12, color: Colors.white60)),
            Text(
              '${provider.planCompletedCommits} / $totalCommits commits (${(progress * 100).toInt()}%)',
              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            color: const Color(0xFF10B981),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 20),
        // Schedule Details
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Next Commit at:', style: TextStyle(fontSize: 12, color: Colors.white54)),
                  Text(
                    provider.nextScheduledCommitTime != null
                        ? DateFormat('HH:mm (yyyy-MM-dd)').format(provider.nextScheduledCommitTime!.toLocal())
                        : 'Checking slots...',
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Time to Next Commit:', style: TextStyle(fontSize: 12, color: Colors.white54)),
                  Text(
                    _formatDuration(timeUntilNext),
                    style: const TextStyle(fontSize: 12, color: Colors.amberAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Plan Ends on:', style: TextStyle(fontSize: 12, color: Colors.white54)),
                  Text(
                    provider.planEndTime != null
                        ? DateFormat('yyyy-MM-dd').format(provider.planEndTime!.toLocal())
                        : 'Calculating...',
                    style: const TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Days Remaining:', style: TextStyle(fontSize: 12, color: Colors.white54)),
                  Text(
                    '$daysRemaining day(s) left',
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () {
              provider.cancelGraphPlan();
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              'Abort Graph Plan',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
