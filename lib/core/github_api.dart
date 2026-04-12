import 'dart:convert';
import 'package:http/http.dart' as http;

class GitHubApi {
  final String token;
  final String owner;
  final String repo;

  GitHubApi({required this.token, required this.owner, required this.repo});

  Future<bool> createOrUpdateFile({
    required String path,
    required String content,
    required String message,
  }) async {
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path');
    
    // Check if file exists to get SHA
    final getResponse = await http.get(
      url,
      headers: {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github.v3+json',
      },
    );

    String? sha;
    if (getResponse.statusCode == 200) {
      final data = jsonDecode(getResponse.body);
      sha = data['sha'];
    }

    final body = {
      'message': message,
      'content': base64Encode(utf8.encode(content)),
    };
    if (sha != null) {
      body['sha'] = sha;
    }

    final putResponse = await http.put(
      url,
      headers: {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    return putResponse.statusCode == 200 || putResponse.statusCode == 201;
  }

  Future<List<String>> getRepositories() async {
    final url = Uri.parse('https://api.github.com/user/repos');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github.v3+json',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => item['name'] as String).toList();
    }
    return [];
  }
}
