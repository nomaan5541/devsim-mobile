import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const apiKey = 'AIzaSyCIaWS8RradSMwJ296ijt-ZUAVgfEzbdXQ';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final models = data['models'] as List<dynamic>;
      print('Available Models:');
      for (var m in models) {
        print(' - ${m['name']}');
      }
    } else {
      print('Failed to list models: ${response.statusCode}');
      print(response.body);
    }
  } catch (e) {
    print('Error: $e');
  }
}
