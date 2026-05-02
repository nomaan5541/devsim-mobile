import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const apiKey = 'AIzaSyCIaWS8RradSMwJ296ijt-ZUAVgfEzbdXQ';
  const ext = 'py';
  const style = 'System Architect style: clean, highly documented, using design patterns and enterprise standards.';
  
  final prompt = '''Act as a Senior $ext Developer with a $style. 
Generate a sophisticated $ext code snippet for a professional repository. 
CRITICAL: Do NOT include any conversation, introductions ("Here is your code"), or summaries. 
OUTPUT ONLY THE VIRGIN CODE. ZERO PLACEHOLDERS.''';

  print('Intelligence Engine: Contacting Gemini Flash (Latest)...');
  
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
          'maxOutputTokens': 512,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
      print('\n--- GENERATED AI CONTENT ---');
      print(text.trim());
      print('-----------------------------\n');
      print('Status: SUCCESS. Intelligence engine is operational.');
    } else {
      print('Status: FAILED. Status Code: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('Status: ERROR. $e');
  }
}
