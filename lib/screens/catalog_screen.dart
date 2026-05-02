import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../models/web_project.dart';
import '../models/dev_persona.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final projects = provider.catalogProjects;

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        title: const Text('500 Days Challenge', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
            center: Alignment(0.8, -0.6),
            radius: 1.5,
            colors: [
              Color(0xFF1E1B4B),
              Color(0xFF0F111A),
            ],
          ),
        ),
        child: projects.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  final isCompleted = project.day <= provider.challengeDay;
                  final isNext = project.day == provider.challengeDay + 1;

                  return _buildProjectCard(context, project, isCompleted, isNext, provider);
                },
              ),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, WebProject project, bool isCompleted, bool isNext, AppProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNext ? const Color(0xFF6366F1) : (isCompleted ? const Color(0xFF10B981).withOpacity(0.5) : Colors.white10),
          width: isNext ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted ? const Color(0xFF10B981).withOpacity(0.2) : Colors.white10,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${project.day}',
              style: TextStyle(
                color: isCompleted ? const Color(0xFF10B981) : Colors.white60,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          project.name,
          style: TextStyle(
            color: isCompleted ? Colors.white70 : Colors.white,
            fontWeight: FontWeight.bold,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          isCompleted ? 'Completed' : (isNext ? 'Up Next' : 'Locked'),
          style: TextStyle(
            color: isNext ? const Color(0xFF6366F1) : Colors.white38,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.psychology_rounded, color: Colors.white38, size: 20),
              onPressed: () => _showAIExplanation(context, project, provider),
            ),
            if (isCompleted)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981))
            else if (isNext)
              ElevatedButton(
                onPressed: () => _confirmCommit(context, project, provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Commit', style: TextStyle(fontSize: 12)),
              )
            else
              const Icon(Icons.lock_outline_rounded, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  void _showAIExplanation(BuildContext context, WebProject project, AppProvider provider) {
    String explanation;
    switch (provider.persona) {
      case DevPersona.architect:
        explanation = 'As an Architect, you should focus on the separation of concerns and maintainability in this ${project.name} project.';
        break;
      case DevPersona.bugFixer:
        explanation = 'Concentrate on making this ${project.name} robust. Ensure there are no performance bottlenecks.';
        break;
      case DevPersona.hacker:
        explanation = 'Build it fast! Speed is everything for ${project.name}.';
        break;
      case DevPersona.fullstack:
        explanation = 'Balance the frontend aesthetics with efficient structure for ${project.name}.';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent),
            SizedBox(width: 12),
            Expanded(child: Text('AI Insight: ${project.name}', style: const TextStyle(color: Colors.white, fontSize: 16))),
          ],
        ),
        content: Text(explanation, style: const TextStyle(color: Colors.white70, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('GOT IT', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _confirmCommit(BuildContext context, WebProject project, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        title: const Text('Start Project Commit?', style: TextStyle(color: Colors.white)),
        content: Text('This will perform 10 automated commits for "${project.name}" to your repository.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.commitCatalogProject(project);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Syncing ${project.name}...')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            child: const Text('Commence Pulse'),
          ),
        ],
      ),
    );
  }
}
