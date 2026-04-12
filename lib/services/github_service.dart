import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'logger_service.dart';

class GitHubService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  final LoggerService _logger = LoggerService();

  static const String _tokenKey = 'github_pat';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<bool> validateToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'DevSim-Mobile-App',
        },
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      _logger.log('Token validation error: $e', type: LogType.error);
      return false;
    }
  }

  Future<bool> createRepo(String token, String name, bool isPrivate) async {
    final response = await http.post(
      Uri.parse('https://api.github.com/user/repos'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
        'User-Agent': 'DevSim-Mobile-App',
      },
      body: jsonEncode({
        'name': name,
        'private': isPrivate,
        'auto_init': true,
      }),
    );
    return response.statusCode == 201;
  }

  Future<bool> createOrUpdateFile({
    required String token,
    required String owner,
    required String repo,
    required String path,
    required String content,
    required String message,
  }) async {
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path');
    
    _logger.log('Attempting commit to $path...', type: LogType.api);

    // Get file info to handle existing files
    final getResponse = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'DevSim-Mobile-App',
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
    if (sha != null) body['sha'] = sha;

    final putResponse = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
        'User-Agent': 'DevSim-Mobile-App',
      },
      body: jsonEncode(body),
    );

    if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
      _logger.log('Commit Successful: $message', type: LogType.success);
      return true;
    } else {
      _logger.log('Commit Failed: ${putResponse.body}', type: LogType.error);
      return false;
    }
  }

  Future<Map<String, dynamic>?> getRepoInfo(String token, String owner, String repo) async {
    final response = await http.get(
      Uri.parse('https://api.github.com/repos/$owner/$repo'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'DevSim-Mobile-App',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }
}
