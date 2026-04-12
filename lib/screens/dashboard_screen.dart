import 'dart:ui';
import '../widgets/heat_map_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A), // Deep midnight background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('DevSim Mobile', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen())),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.6),
            radius: 1.5,
            colors: [
              Color(0xFF1E1B4B), // Indigo
              Color(0xFF0F111A), // Deep Midnight
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 100, left: 20, right: 20, bottom: 100),
          child: Column(
            children: [
              _buildStatusHeader(provider),
              const SizedBox(height: 24),
              _buildGlassCard(
                child: HeatMapWidget(data: provider.heatmapData),
              ),
              const SizedBox(height: 24),
              _buildStatsBar(provider),
              const SizedBox(height: 24),
              _buildGlassCard(
                child: _buildProgressContent(provider),
              ),
              const SizedBox(height: 24),
              if (provider.commitHistory.isNotEmpty) ...[
                _buildGlassCard(
                  child: _buildCommittedFilesContent(provider),
                ),
                const SizedBox(height: 24),
              ],
              _buildGlassCard(
                child: _buildLogPreviewContent(context),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: provider.isRunning ? provider.toggleRunning : () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SchedulerSetupScreen()));
        },
        backgroundColor: const Color(0xFF6366F1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(provider.isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded),
        label: Text(provider.isRunning ? 'Stop Simulation' : 'Start Session', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildStatusHeader(AppProvider provider) {
    final isRunning = provider.isRunning;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isRunning ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFF6366F1).withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isRunning ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isRunning ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFF6366F1).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(isRunning ? Icons.bolt_rounded : Icons.power_settings_new_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRunning ? 'SIMULATOR ACTIVE' : 'SYSTEM IDLE',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                Text(
                  isRunning ? 'Targeting: ${provider.repo}' : 'Waiting for pulse parameters',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
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
        _buildStatItem('Total Pulse', provider.completedCommits.toString(), Icons.speed_rounded, Colors.orangeAccent),
        const SizedBox(width: 12),
        _buildStatItem('Files', provider.commitHistory.length.toString(), Icons.snippet_folder_rounded, Colors.lightBlueAccent),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: _buildGlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressContent(AppProvider provider) {
    final progress = provider.targetCommits > 0 ? (provider.completedCommits / provider.targetCommits) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Session Progress', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
        Text('${provider.completedCommits} of ${provider.targetCommits} pulses synced', style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }

  Widget _buildCommittedFilesContent(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Committed Files', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.commitHistory.take(5).length,
          separatorBuilder: (_, __) => Divider(height: 24, color: Colors.white.withOpacity(0.05)),
          itemBuilder: (context, index) {
            final commit = provider.commitHistory[index];
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                  child: Icon(_getFileIcon(commit.path), size: 16, color: Colors.white60),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(commit.path, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
                      Text(commit.message, style: const TextStyle(fontSize: 11, color: Colors.white38)),
                    ],
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(commit.timestamp),
                  style: const TextStyle(fontSize: 11, color: Colors.white24),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  IconData _getFileIcon(String path) {
    if (path.endsWith('.dart')) return Icons.code_rounded;
    if (path.endsWith('.md')) return Icons.description_rounded;
    if (path.endsWith('.yaml')) return Icons.settings_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Widget _buildLogPreviewContent(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Pulse Logs', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LogsScreen())),
              child: const Text('View All', style: TextStyle(color: Color(0xFF6366F1), fontSize: 12)),
            )
          ],
        ),
        Container(
          height: 100,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(16)),
          child: const Text(
            '> Intelligence engine operational...\n> Pulse pattern analysis active...',
            style: TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 11),
          ),
        )
      ],
    );
  }
}
