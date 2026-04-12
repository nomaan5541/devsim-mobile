import 'package:flutter/material.dart';

class HeatMapWidget extends StatelessWidget {
  final List<int> data;
  const HeatMapWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contribution Activity',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E212D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: data.map((count) => _buildSquare(count)).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Less', style: TextStyle(fontSize: 10, color: Colors.white38)),
                  const SizedBox(width: 8),
                  _buildSquare(0),
                  const SizedBox(width: 4),
                  _buildSquare(2),
                  const SizedBox(width: 4),
                  _buildSquare(5),
                  const SizedBox(width: 4),
                  _buildSquare(10),
                  const SizedBox(width: 8),
                  const Text('More', style: TextStyle(fontSize: 10, color: Colors.white38)),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSquare(int count) {
    Color color;
    if (count == 0) {
      color = Colors.white12;
    } else if (count < 3) {
      color = const Color(0xFF0E4429);
    } else if (count < 6) {
      color = const Color(0xFF006D32);
    } else if (count < 9) {
      color = const Color(0xFF26A641);
    } else {
      color = const Color(0xFF39D353);
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
