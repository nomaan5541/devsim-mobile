import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_provider.dart';
import '../services/logger_service.dart';
import '../models/dev_persona.dart';
import '../models/commit_record.dart';
import '../widgets/real_time_graph_widget.dart';
import 'scheduler_setup_screen.dart';
import 'settings_screen.dart';
import 'logs_screen.dart';
import 'analytics_screen.dart';

import 'studio_screen.dart';
import 'catalog_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().requestPermissions();
    });
  }

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
            icon: const Icon(Icons.rocket_launch_rounded, color: Colors.orangeAccent),
            tooltip: 'AI Studio',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudioScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined, color: Colors.amberAccent),
            tooltip: '500 Days Challenge',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
          ),
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
              _buildPermissionBanner(provider),
              const SizedBox(height: 12),
              _buildStatusHeader(provider),
              const SizedBox(height: 24),
              _buildChallengeProgress(context, provider),
              const SizedBox(height: 24),
              _buildChallengeStats(provider),
              const SizedBox(height: 24),
              _buildPersonaSelection(provider),
              const SizedBox(height: 24),
              _buildLiveConsole(provider),
              const SizedBox(height: 24),
              _buildDailyJournal(provider),
              const SizedBox(height: 24),
              _buildAchievements(provider),
              const SizedBox(height: 24),
              _buildGlassCard(
                child: RealTimeGraphWidget(
                  weeks: provider.githubContributionsWeeks,
                  isLoading: provider.isLoadingContributions,
                  onRefresh: () => provider.fetchRealTimeGitHubGraph(),
                ),
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

  Widget _buildPermissionBanner(AppProvider provider) {
    return GestureDetector(
      onTap: () => provider.requestPermissions(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withOpacity(0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.security_rounded, color: Colors.amberAccent, size: 18),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Background & File permissions required for 24/7 sync.',
                style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.amberAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeProgress(BuildContext context, AppProvider provider) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('500 DAYS CHALLENGE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                  Text('Level Up Your Career', style: TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Explore', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircularProgressIndicator(
                value: provider.challengeDay / 500,
                backgroundColor: Colors.white12,
                color: Colors.amberAccent,
                strokeWidth: 6,
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${provider.challengeDay} / 500', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Text('Days Completed', style: TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveConsole(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('LIVE ACTIVITY CONSOLE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white60, fontSize: 12, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildGlassCard(
          padding: const EdgeInsets.all(12),
          child: Container(
            height: 120,
            width: double.infinity,
            child: provider.liveLogs.isEmpty 
              ? const Center(child: Text('Awaiting system pulse...', style: TextStyle(color: Colors.white24, fontSize: 11)))
              : ListView.builder(
                  itemCount: provider.liveLogs.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '> ${provider.liveLogs[index]}',
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontFamily: 'monospace'),
                    ),
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyJournal(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DAILY DEV LOG', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white60, fontSize: 12, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        if (provider.dailyJournal.isEmpty)
          const Text('No entries yet. Complete a day to generate your log.', style: TextStyle(color: Colors.white24, fontSize: 11))
        else
          ...provider.dailyJournal.take(3).map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildGlassCard(
              padding: const EdgeInsets.all(16),
              child: Text(entry, style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4)),
            ),
          )).toList(),
      ],
    );
  }

  Widget _buildPersonaSelection(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DEVELOPER PERSONA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white60, fontSize: 12, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildGlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: DevPersona.values.map((p) {
              final isSelected = provider.persona == p;
              return ListTile(
                onTap: () => provider.setPersona(p),
                leading: CircleAvatar(
                  backgroundColor: isSelected ? const Color(0xFF6366F1).withOpacity(0.2) : Colors.white10,
                  child: Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.person_outline_rounded,
                    color: isSelected ? const Color(0xFF6366F1) : Colors.white24,
                  ),
                ),
                title: Text(p.displayName, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                subtitle: Text(p.personaDescription, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                trailing: isSelected ? const Icon(Icons.star_rounded, color: Colors.amberAccent) : null,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeStats(AppProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildGlassCard(
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${provider.currentStreak} DAYS', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                    const Text('CURRENT STREAK', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.0)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildGlassCard(
            child: Row(
              children: [
                const Icon(Icons.auto_graph_rounded, color: Color(0xFF6366F1), size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${(provider.challengeDay / 5).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                    const Text('TOTAL PROGRESS', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.0)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievements(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MILESTONES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white60, fontSize: 12, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: provider.achievements.length,
            itemBuilder: (context, index) {
              final a = provider.achievements[index];
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: a.isUnlocked ? Colors.amber.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: a.isUnlocked ? Colors.amber.withOpacity(0.3) : Colors.white10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(a.icon, color: a.isUnlocked ? Colors.amberAccent : Colors.white24, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      a.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: a.isUnlocked ? Colors.white : Colors.white24, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isRunning ? 'SIMULATOR ACTIVE' : 'SYSTEM IDLE',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        provider.persona.displayName.toUpperCase().split(' ').last,
                        style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Text(
                  isRunning ? 'Targeting: ${provider.repo}' : 'Waiting for pulse parameters',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.key_outlined, size: 10, color: Colors.white38),
                    const SizedBox(width: 4),
                    Text(
                      'Token Expiry: ${provider.tokenExpiryString}',
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
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
        _buildStatItem('Total Pulses', provider.totalPulses.toString(), Icons.speed_rounded, Colors.orangeAccent),
        const SizedBox(width: 12),
        _buildStatItem('Total Files', provider.lifetimeFiles.toString(), Icons.snippet_folder_rounded, Colors.lightBlueAccent),
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
          height: 120,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(16)),
          child: StreamBuilder<List<AppLog>>(
            stream: LoggerService().logStream,
            initialData: LoggerService().currentLogs,
            builder: (context, snapshot) {
              final logs = snapshot.data ?? [];
              final preview = logs.take(4).map((l) => '> ${l.message}').join('\n');
              return Text(
                preview.isEmpty ? '> Intelligence engine operational...\n> Pulse pattern analysis active...' : preview,
                style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 11),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
        )
      ],
    );
  }
}
