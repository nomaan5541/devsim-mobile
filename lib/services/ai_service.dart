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
        _logger.log('Intelligence Engine: Successfully generated pulse content.', type: LogType.success);
        // Clean up markdown block indicators if any
        return text.replaceAll('```python', '').replaceAll('```md', '').replaceAll('```json', '').replaceAll('```', '').trim();
      } else {
        _logger.log('Intelligence Engine Error: API Key or Quota issue detected.', type: LogType.error);
        return null;
      }
    } catch (e) {
      _logger.log('AI Service Internal Exception: $e', type: LogType.error);
      return null;
    }
  }

  String buildCodePrompt(String ext) {
    return 'Act as a Senior Software Engineer. Generate a sophisticated, professional $ext code snippet for an enterprise repository. Avoid placeholders. Provide only the code, no markdown or explanations.';
  }

  String buildAnalysisPrompt() {
    return 'Generate a professional, high-level technical analysis of a recent module deployment. Focus on performance metrics or architectural improvements. Keep it realistic and under 80 words.';
  }
}
