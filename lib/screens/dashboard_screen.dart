import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
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
            _buildQuickActions(context),
            const SizedBox(height: 24),
            _buildProgressCard(provider),
            const SizedBox(height: 24),
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
            decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
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
                  isRunning ? 'Background worker connected' : 'Pulse waiting for trigger',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _buildActionItem(context, 'Historical Logs', Icons.history, const LogsScreen()),
        const SizedBox(width: 16),
        _buildActionItem(context, 'Analytics', Icons.bar_chart, null),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, String title, IconData icon, Widget? target) {
    return Expanded(
      child: InkWell(
        onTap: target != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => target)) : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E212D),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF6366F1)),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 12)),
            ],
          ),
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
            const Text('Session Progress', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white12,
              color: const Color(0xFF10B981),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${provider.completedCommits} Commits Done', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
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
                '> System initialized...\n> Waiting for session parameters...',
                style: TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 12),
              ),
            )
          ],
        ),
      ),
    );
  }
}
