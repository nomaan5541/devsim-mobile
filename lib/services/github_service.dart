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
    String? branch,
  }) async {
    final query = branch != null ? '?ref=$branch' : '';
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path$query');
    
    _logger.log('Attempting commit to $path${branch != null ? " [$branch]" : ""}...', type: LogType.api);

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
    if (branch != null) body['branch'] = branch;

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

  Future<bool> createBranch(String token, String owner, String repo, String branchName, String baseBranch) async {
    // 1. Get the SHA of the base branch
    final refUrl = Uri.parse('https://api.github.com/repos/$owner/$repo/git/ref/heads/$baseBranch');
    final refResponse = await http.get(
      refUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'DevSim-Mobile-App',
      },
    );

    if (refResponse.statusCode != 200) return false;
    final sha = jsonDecode(refResponse.body)['object']['sha'];

    // 2. Create the new reference
    final createUrl = Uri.parse('https://api.github.com/repos/$owner/$repo/git/refs');
    final createResponse = await http.post(
      createUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
        'User-Agent': 'DevSim-Mobile-App',
      },
      body: jsonEncode({
        'ref': 'refs/heads/$branchName',
        'sha': sha,
      }),
    );

    return createResponse.statusCode == 201;
  }

  Future<int?> createPullRequest(String token, String owner, String repo, String title, String body, String head, String base) async {
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/pulls');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
        'User-Agent': 'DevSim-Mobile-App',
      },
      body: jsonEncode({
        'title': title,
        'body': body,
        'head': head,
        'base': base,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body)['number'] as int;
    }
    return null;
  }

  Future<bool> mergePullRequest(String token, String owner, String repo, int prNumber) async {
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/pulls/$prNumber/merge');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
        'User-Agent': 'DevSim-Mobile-App',
      },
      body: jsonEncode({
        'merge_method': 'merge',
      }),
    );

    return response.statusCode == 200;
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
