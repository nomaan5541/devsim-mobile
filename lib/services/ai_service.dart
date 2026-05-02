import 'dart:convert';
import 'package:http/http.dart' as http;
import 'logger_service.dart';
import '../models/dev_persona.dart';

class AiService {
  final LoggerService _logger = LoggerService();

  // Standard Templates for diverse commits when AI is disabled or fails
  static const Map<String, List<String>> _templates = {
    'py': [
      'def calculate_metrics(data):\n    """Sophisticated data analysis logic."""\n    return {k: sum(v)/len(v) for k, v in data.items()}',
      'class IntelligenceEngine:\n    def __init__(self):\n        self.active = True\n    def process_pulse(self):\n        pass',
      'import threading\nimport time\n\ndef background_worker():\n    while True:\n        print("Syncing pulse...")\n        time.sleep(60)',
    ],
    'dart': [
      'class DevPulse {\n  final DateTime timestamp;\n  final String id;\n  DevPulse({required this.timestamp, required this.id});\n}',
      'class PulseDiagnostic {\n  void main() {\n    debugPrint("Pulse Engine Diagnostic Initiated.");\n    runApp(const DevSimApp());\n  }\n}',
      'abstract class SyncService {\n  Future<bool> pushChanges();\n  Stream<double> get progress;\n}',
    ],
    'js': [
      'const processData = (payload) => {\n  return payload.map(item => ({ ...item, processed: true }));\n};',
      'export default class Analytics {\n  constructor() {\n    this.pulses = 0;\n  }\n  track() { this.pulses++; }\n}',
      'fetch("/api/pulse").then(res => res.json()).then(console.log);',
    ],
    'yaml': [
      'version: 1.2.0\nenvironment:\n  sdk: ^3.0.0\ndependencies:\n  provider: ^6.0.0\n  http: ^1.1.0',
      'metadata:\n  name: devsim-pulse-engine\n  owner: system-architect\n  tags: [sim, ai, git]',
    ]
  };

  String getTemplateContent(String ext) {
    if (!_templates.containsKey(ext)) return "// Pulse Sync Item\n";
    final list = _templates[ext]!;
    return list[DateTime.now().millisecond % list.length];
  }

  Future<String?> generateContent({
    required String apiKey,
    required String prompt,
    String? fallbackExt,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$apiKey',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
             'temperature': 0.7,
             'topK': 40,
             'topP': 0.95,
             'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
        _logger.log('Intelligence Engine: Successfully generated pulse content.', type: LogType.success);
        
        return _cleanAiOutput(text);
      } else {
        _logger.log('Intelligence Engine Error: API Key or Quota issue. Using template fallback...', type: LogType.warning);
        return fallbackExt != null ? getTemplateContent(fallbackExt) : null;
      }
    } catch (e) {
      _logger.log('AI Service Internal Exception: $e. Using template fallback...', type: LogType.warning);
      return fallbackExt != null ? getTemplateContent(fallbackExt) : null;
    }
  }

  String _cleanAiOutput(String text) {
    // Remove markdown code blocks like ```python ... ```
    final codeBlockRegex = RegExp(r'```(?:\w+)?\s*([\s\S]*?)```');
    final match = codeBlockRegex.firstMatch(text);
    if (match != null) {
      return match.group(1)?.trim() ?? text.trim();
    }
    
    // Fallback cleanup
    return text
        .replaceAll(RegExp(r'^```(?:\w+)?'), '')
        .replaceAll(RegExp(r'```$'), '')
        .trim();
  }

  String buildCodePrompt(String ext, DevPersona persona) {
    String style;
    switch (persona) {
      case DevPersona.architect:
        style = 'System Architect style: clean, highly documented, using design patterns and enterprise standards.';
        break;
      case DevPersona.bugFixer:
        style = 'Technical BugFixer style: focuses on error handling, robustness, and performance optimizations.';
        break;
      case DevPersona.hacker:
        style = 'Rapid Hacker style: advanced, terse, clever logic using non-standard but highly efficient patterns.';
        break;
      case DevPersona.fullstack:
        style = 'Fullstack Ninja style: cohesive integration, type safety, and seamless communication between layers.';
        break;
    }

    return '''Act as a Senior $ext Developer with a $style. 
Generate a sophisticated $ext code snippet for a professional repository. 
CRITICAL: Do NOT include any conversation, introductions ("Here is your code"), or summaries. 
OUTPUT ONLY THE VIRGIN CODE. ZERO PLACEHOLDERS.''';
  }

  String buildAnalysisPrompt(DevPersona persona) {
    return 'Act as a developer with a ${persona.displayName} persona. Generate a professional, concise technical update on recent progress. DO NOT use conversational filler. Focus strictly on achievement. Keep it under 60 words.';
  }

  String buildReviewPrompt(String codeSnippet) {
    return 'Act as a Senior Peer Reviewer. Provide a technically detailed comment for a PR containing this code: $codeSnippet. Focus on logic. NO INTRODUCTIONS. Keep it under 50 words.';
  }

  String buildJournalPrompt(List<String> achievements) {
    return 'Act as a Software Engineer writing a Daily Dev Log entry. Summarize these: ${achievements.join(", ")}. Narrative paragraph. NO CONVERSATION. Keep it under 100 words.';
  }
}
