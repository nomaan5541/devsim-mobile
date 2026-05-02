import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Intelligence Analytics', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.8, 0.6),
            radius: 1.5,
            colors: [
              Color(0xFF1E1B4B),
              Color(0xFF0F111A),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.only(top: 120, left: 24, right: 24, bottom: 40),
          children: [
             _buildPersonaCard(provider),
             const SizedBox(height: 24),
             _buildStatGrid(provider),
             const SizedBox(height: 24),
             _buildInsightCard(provider),
             const SizedBox(height: 24),
             _buildHistoryCard(provider),
          ],
        ),
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
          padding: padding ?? const EdgeInsets.all(24),
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

  Widget _buildPersonaCard(AppProvider provider) {
    return _buildGlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_rounded, color: Color(0xFF818CF8), size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.persona.displayName.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                Text(
                  provider.persona.personaDescription,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatGrid(AppProvider provider) {
    return Row(
      children: [
        Expanded(child: _buildStatBox('LOC Simulated', provider.totalLocSimulated.toString(), Icons.analytics_rounded, Colors.greenAccent)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatBox('PRs Processed', provider.completedCommits > 0 ? (provider.completedCommits / 3).ceil().toString() : '0', Icons.merge_type_rounded, Colors.orangeAccent)),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return _buildGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInsightCard(AppProvider provider) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Session Wisdom', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          const Text(
            'The intelligence core is currently optimizing repository structure. Activity patterns suggest a high focus on technical debt reduction and module isolation.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.offline_bolt_rounded, color: Colors.amberAccent, size: 16),
              const SizedBox(width: 8),
              Text('Intelligence Level: ${provider.isAiEnabled ? "High" : "Standard"}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHistoryCard(AppProvider provider) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Growth', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          _buildGrowthRow('Architecture Complexity', 0.85, Colors.blueAccent),
          const SizedBox(height: 16),
          _buildGrowthRow('Automation Coverage', 0.92, Colors.tealAccent),
          const SizedBox(height: 16),
          _buildGrowthRow('Simulated Seniority', 0.78, Colors.purpleAccent),
        ],
      ),
    );
  }

  Widget _buildGrowthRow(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
            Text('${(value * 100).toInt()}%', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.white10,
          color: color,
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }
}
