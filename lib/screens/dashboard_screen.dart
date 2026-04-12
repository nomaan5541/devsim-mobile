import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_provider.dart';
import '../models/commit_record.dart';
import 'scheduler_setup_screen.dart';
import 'settings_screen.dart';
import 'logs_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStatusHeader(provider),
            const SizedBox(height: 24),
            _buildStatsBar(provider),
            const SizedBox(height: 24),
            _buildProgressCard(provider),
            const SizedBox(height: 24),
            if (provider.commitHistory.isNotEmpty) ...[
              _buildCommittedFilesList(provider),
              const SizedBox(height: 24),
            ],
            _buildLogPreview(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: provider.isRunning ? provider.toggleRunning : () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SchedulerSetupScreen()));
        },
        backgroundColor: const Color(0xFF6366F1),
        icon: Icon(provider.isRunning ? Icons.stop : Icons.play_arrow),
        label: Text(provider.isRunning ? 'Stop Simulation' : 'Setup Session'),
      ),
    );
  }

  Widget _buildStatusHeader(AppProvider provider) {
    final isRunning = provider.isRunning;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRunning 
            ? [const Color(0xFF10B981), const Color(0xFF059669)]
            : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: Icon(isRunning ? Icons.bolt : Icons.power_settings_new, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRunning ? 'Simulator Active' : 'System Idle',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  isRunning ? 'Activity: ${provider.repo}' : 'Pulse waiting for trigger',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatsBar(AppProvider provider) {
    return Row(
      children: [
        _buildStatItem('Success Rate', '${provider.successRate.toInt()}%', Icons.check_circle_outline, Colors.tealAccent),
        const SizedBox(width: 12),
        _buildStatItem('Total Pulse', provider.completedCommits.toString(), Icons.speed, Colors.orangeAccent),
        const SizedBox(width: 12),
        _buildStatItem('Files', provider.commitHistory.length.toString(), Icons.insert_drive_file_outlined, Colors.lightBlueAccent),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E212D),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(AppProvider provider) {
    final progress = provider.targetCommits > 0 ? (provider.completedCommits / provider.targetCommits) : 0.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Session Progress', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white12,
              color: const Color(0xFF10B981),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Text('${provider.completedCommits} of ${provider.targetCommits} pulses synced', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommittedFilesList(AppProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Committed Files', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.commitHistory.take(5).length,
              separatorBuilder: (_, __) => const Divider(height: 24, color: Colors.white10),
              itemBuilder: (context, index) {
                final commit = provider.commitHistory[index];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                      child: Icon(_getFileIcon(commit.path), size: 16, color: Colors.white70),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(commit.path, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          Text(commit.message, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(commit.timestamp),
                      style: const TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String path) {
    if (path.endsWith('.dart')) return Icons.code;
    if (path.endsWith('.md')) return Icons.description;
    if (path.endsWith('.yaml')) return Icons.settings_applications;
    return Icons.file_present;
  }

  Widget _buildLogPreview(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Pulse Logs', style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LogsScreen())),
                  child: const Text('View All'),
                )
              ],
            ),
            Container(
              height: 100,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
              child: const Text(
                '> Engine operational...\n> Listening for pulse signals...',
                style: TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 12),
              ),
            )
          ],
        ),
      ),
    );
  }
}
