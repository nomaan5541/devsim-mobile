import 'dart:convert';
import 'package:http/http.dart' as http;
import 'logger_service.dart';

class AiService {
  final LoggerService _logger = LoggerService();

  Future<String?> generateContent({
    required String apiKey,
    required String prompt,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
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
        // Clean up markdown block indicators if any
        return text.replaceAll('```python', '').replaceAll('```md', '').replaceAll('```json', '').replaceAll('```', '').trim();
      } else {
        _logger.log('Gemini API Error: ${response.statusCode} - ${response.body}', type: LogType.error);
        return null;
      }
    } catch (e) {
      _logger.log('AI Service Exception: $e', type: LogType.error);
      return null;
    }
  }

  String buildCodePrompt(String ext) {
    return 'Generate a realistic $ext code snippet for a developer project. Do not include markdown formatting. Just the code.';
  }

  String buildAnalysisPrompt() {
    return 'Generate a concise, professional log analysis report or status update for a software project. Keep it under 100 words.';
  }
}
