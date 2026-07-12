import 'package:flutter/material.dart';

class RealTimeGraphWidget extends StatelessWidget {
  final List<List<Map<String, dynamic>>>? weeks;
  final bool isLoading;
  final VoidCallback onRefresh;

  const RealTimeGraphWidget({
    super.key,
    required this.weeks,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REAL-TIME GITHUB GRAPH',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.white60,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Syncing contribution activity',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
            IconButton(
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF6366F1),
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white60,
                      size: 20,
                    ),
              tooltip: 'Sync Graph',
              onPressed: isLoading ? null : onRefresh,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF12131C),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isLoading)
                _buildLoadingState()
              else if (weeks == null || weeks!.isEmpty)
                _buildEmptyState()
              else
                _buildGraph(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Less', style: TextStyle(fontSize: 9, color: Colors.white38)),
                  const SizedBox(width: 6),
                  _buildSquare(0),
                  const SizedBox(width: 4),
                  _buildSquare(2),
                  const SizedBox(width: 4),
                  _buildSquare(5),
                  const SizedBox(width: 4),
                  _buildSquare(8),
                  const SizedBox(width: 4),
                  _buildSquare(12),
                  const SizedBox(width: 6),
                  const Text('More', style: TextStyle(fontSize: 9, color: Colors.white38)),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 110,
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF6366F1),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Retrieving GitHub API metrics...',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 110,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bar_chart_rounded, color: Colors.white24, size: 36),
          const SizedBox(height: 8),
          const Text(
            'No GitHub Contribution Data',
            style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Check internet connection and token scopes.',
            style: TextStyle(color: Colors.white30, fontSize: 10),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry Fetch', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraph() {
    // Standardize weeks list to always align Sunday to Saturday.
    final List<List<Map<String, dynamic>?>> alignedWeeks = [];
    
    for (var weekData in weeks!) {
      final List<Map<String, dynamic>?> alignedWeek = List.filled(7, null);
      for (var day in weekData) {
        if (day['date'] != null) {
          final date = DateTime.parse(day['date']);
          // Dart weekday: 1 (Mon) - 7 (Sun)
          // Grid rows: 0 (Sun) - 6 (Sat)
          final gridIndex = date.weekday == 7 ? 0 : date.weekday;
          if (gridIndex >= 0 && gridIndex < 7) {
            alignedWeek[gridIndex] = day;
          }
        }
      }
      alignedWeeks.add(alignedWeek);
    }

    return Container(
      height: 110,
      alignment: Alignment.center,
      child: Scrollbar(
        thumbVisibility: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Weekday labels
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDayLabel('Sun'),
                  const SizedBox(height: 3),
                  _buildDayLabel('Mon'),
                  const SizedBox(height: 3),
                  _buildDayLabel('Tue'),
                  const SizedBox(height: 3),
                  _buildDayLabel('Wed'),
                  const SizedBox(height: 3),
                  _buildDayLabel('Thu'),
                  const SizedBox(height: 3),
                  _buildDayLabel('Fri'),
                  const SizedBox(height: 3),
                  _buildDayLabel('Sat'),
                ],
              ),
              const SizedBox(width: 8),
              // Grid columns
              ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: alignedWeeks.length,
                itemBuilder: (context, weekIdx) {
                  final week = alignedWeeks[weekIdx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(7, (dayIdx) {
                        final day = week[dayIdx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1.5),
                          child: _buildContributionSquare(day),
                        );
                      }),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayLabel(String label) {
    // Only show Sun, Tue, Thu, Sat to match GitHub's sparseness
    final shouldShow = label == 'Sun' || label == 'Tue' || label == 'Thu' || label == 'Sat';
    return SizedBox(
      height: 12,
      width: 24,
      child: Text(
        shouldShow ? label : '',
        style: const TextStyle(fontSize: 8, color: Colors.white24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildContributionSquare(Map<String, dynamic>? day) {
    if (day == null) {
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(2.5),
        ),
      );
    }

    final count = day['count'] as int? ?? 0;
    return Tooltip(
      message: '$count contributions on ${day['date']}',
      preferOrientedBubble: false,
      child: _buildSquare(count),
    );
  }

  Widget _buildSquare(int count) {
    Color color;
    if (count == 0) {
      color = const Color(0xFF161B22);
    } else if (count < 3) {
      color = const Color(0xFF0E4429);
    } else if (count < 6) {
      color = const Color(0xFF006D32);
    } else if (count < 10) {
      color = const Color(0xFF26A641);
    } else {
      color = const Color(0xFF39D353);
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2.5),
        border: Border.all(
          color: count == 0 ? Colors.white.withOpacity(0.02) : Colors.transparent,
          width: 0.5,
        ),
      ),
    );
  }
}
