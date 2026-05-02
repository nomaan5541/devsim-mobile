import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../models/staged_file.dart';
import '../models/dev_persona.dart';

class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();
  DevPersona _selectedPersona = DevPersona.architect;
  String _generatedCode = '';
  bool _isGenerating = false;
  String _selectedExtension = 'py';

  @override
  void dispose() {
    _promptController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  void _generateCode() async {
    final provider = context.read<AppProvider>();
    if (_promptController.text.isEmpty || provider.googleApiKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a prompt and ensure Gemini API Key is set.')),
      );
      return;
    }

    setState(() => _isGenerating = true);
    
    // In a real app, we'd use AiService through Provider
    // For now, we'll use the provider logic
    try {
      // We'll simulate the AI call if needed or use the real one
      // But we want to use the buildCodePrompt logic
      // Note: We'll assume the user wants the exact prompt they typed + persona context
      final aiContent = await provider.generateManualAiContent(
        prompt: _promptController.text,
        persona: _selectedPersona,
        extension: _selectedExtension,
      );

      if (aiContent != null) {
        setState(() => _generatedCode = aiContent);
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void _addToStaging() {
    if (_generatedCode.isEmpty || _pathController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generate code and set a filename first.')),
      );
      return;
    }

    final file = StagedFile(
      path: _pathController.text,
      content: _generatedCode,
      prompt: _promptController.text,
      timestamp: DateTime.now(),
    );

    context.read<AppProvider>().addToStaging(file);
    setState(() {
      _generatedCode = '';
      _promptController.clear();
      _pathController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('The AI Studio', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1B4B), Color(0xFF0F111A)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.only(top: 120, left: 20, right: 20, bottom: 40),
          children: [
            _buildEditorSection(provider),
            const SizedBox(height: 24),
            _buildStagingSection(provider),
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
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildEditorSection(AppProvider provider) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Intelligence Prototyping', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              DropdownButton<DevPersona>(
                value: _selectedPersona,
                dropdownColor: const Color(0xFF1E1B4B),
                style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12),
                underline: Container(),
                items: DevPersona.values.map((p) => DropdownMenuItem(value: p, child: Text(p.displayName))).toList(),
                onChanged: (v) => setState(() => _selectedPersona = v!),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _promptController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Describe the feature or module to generate...',
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pathController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Filename (e.g. core/util.py)',
                    hintStyle: const TextStyle(color: Colors.white24),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                child: DropdownButton<String>(
                  value: _selectedExtension,
                  dropdownColor: const Color(0xFF1E1B4B),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  underline: Container(),
                  items: ['py', 'dart', 'js', 'yaml'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _selectedExtension = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generateCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectanglePlatform.borderRadius(BorderRadius.circular(16)),
              ),
              child: _isGenerating 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Generate Intelligence', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          if (_generatedCode.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(16)),
              child: Text(
                _generatedCode,
                style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 11),
                maxLines: 15,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _addToStaging,
              icon: const Icon(Icons.add_task_rounded, size: 18),
              label: const Text('Add to Staging Area'),
              style: TextButton.styleFrom(foregroundColor: Colors.orangeAccent),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildStagingSection(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Staging Area (${provider.stagingArea.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            if (provider.stagingArea.isNotEmpty)
              TextButton(onPressed: provider.clearStaging, child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontSize: 12))),
          ],
        ),
        const SizedBox(height: 12),
        if (provider.stagingArea.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No files staged for deployment.', style: TextStyle(color: Colors.white24, fontSize: 12)))),
        ...provider.stagingArea.asMap().entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildGlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.description_rounded, color: Colors.blueAccent),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.value.path, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('${entry.value.content.length} characters generated', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => provider.removeFromStaging(entry.key),
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white24, size: 20),
                )
              ],
            ),
          ),
        )),
        if (provider.stagingArea.isNotEmpty) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: provider.isProcessingBatch ? null : () => _showRepoSelector(context, provider),
              icon: provider.isProcessingBatch 
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.cloud_upload_rounded),
              label: Text(provider.isProcessingBatch ? 'Pushing to GitHub...' : 'Deploy Staged Files'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black87,
                shape: RoundedRectanglePlatform.borderRadius(BorderRadius.circular(16)),
              ),
            ),
          ),
        ]
      ],
    );
  }

  void _showRepoSelector(BuildContext context, AppProvider provider) {
    String selectedRepo = provider.repo ?? '';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1B4B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Target Repository', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter repository name...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              controller: TextEditingController(text: selectedRepo),
              onChanged: (v) => selectedRepo = v,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (selectedRepo.isNotEmpty) {
                    Navigator.pop(context);
                    provider.pushStagingToGitHub(selectedRepo);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                child: const Text('Confirm & Push Pulses', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// Fixed for Flutter error in snippet
class RoundedRectanglePlatform {
  static RoundedRectangleBorder borderRadius(BorderRadius radius) => RoundedRectangleBorder(borderRadius: radius);
}
