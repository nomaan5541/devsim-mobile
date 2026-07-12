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
  static const String _expiryKey = 'github_pat_expiry';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> saveTokenExpiry(String? expiry) async {
    if (expiry == null) {
      await _storage.delete(key: _expiryKey);
    } else {
      await _storage.write(key: _expiryKey, value: expiry);
    }
  }

  Future<String?> getTokenExpiry() async {
    return await _storage.read(key: _expiryKey);
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
      
      if (response.statusCode == 200) {
        final expiry = response.headers['github-authentication-token-expiration'];
        await saveTokenExpiry(expiry);
        return true;
      }
      return false;
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
    if (response.statusCode == 201) {
      _logger.log('GitHub API: Repo "$name" created successfully.', type: LogType.success);
      return true;
    } else {
      _logger.log('GitHub API: Repo creation failed (${response.statusCode}): ${response.body}', type: LogType.error);
      return false;
    }
  }

  /// Creates a repo and returns the owner login from GitHub's response.
  /// Returns null if creation failed.
  Future<String?> createRepoAndGetOwner(String token, String name, bool isPrivate) async {
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
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final ownerLogin = data['owner']?['login'] as String?;
      _logger.log('GitHub API: Repo "$name" created under owner "$ownerLogin".', type: LogType.success);
      return ownerLogin;
    } else if (response.statusCode == 422) {
      // 422 = repo already exists, try to get the owner
      _logger.log('GitHub API: Repo "$name" already exists. Fetching owner...', type: LogType.info);
      final user = await getCurrentUser(token);
      return user?['login'] as String?;
    } else {
      _logger.log('GitHub API: Repo creation failed (${response.statusCode}): ${response.body}', type: LogType.error);
      return null;
    }
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

  Future<bool> createPRComment(String token, String owner, String repo, int prNumber, String body) async {
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/issues/$prNumber/comments');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
        'User-Agent': 'DevSim-Mobile-App',
      },
      body: jsonEncode({
        'body': body,
      }),
    );

    return response.statusCode == 201;
  }

  Future<String?> getDefaultBranch(String token, String owner, String repo) async {
    try {
      final info = await getRepoInfo(token, owner, repo);
      if (info != null) {
        return info['default_branch'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getCurrentUser(String token) async {
    final response = await http.get(
      Uri.parse('https://api.github.com/user'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'DevSim-Mobile-App',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    _logger.log('Failed to fetch user profile: ${response.statusCode}', type: LogType.error);
    return null;
  }

  Future<Map<String, dynamic>?> getRepoInfo(String token, String owner, String repo) async {
    // Handle empty owner/repo gracefully
    if (owner.isEmpty || repo.isEmpty) return null;

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
    } else {
      _logger.log('Repo check failed: ${response.statusCode} - ${response.reasonPhrase}. Ensure repo name and token permissions are correct.', type: LogType.error);
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getFolderContents(String token, String owner, String repo, String path) async {
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'DevSim-Mobile-App',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
    }
    return null;
  }

  Future<List<dynamic>?> getContributionCalendar(String token) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.github.com/graphql'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent': 'DevSim-Mobile-App',
        },
        body: jsonEncode({
          'query': '''
            query {
              viewer {
                contributionsCollection {
                  contributionCalendar {
                    totalContributions
                    weeks {
                      contributionDays {
                        contributionCount
                        date
                        color
                      }
                    }
                  }
                }
              }
            }
          '''
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['errors'] != null) {
          _logger.log('GraphQL errors: ${body['errors']}', type: LogType.error);
          return null;
        }
        final calendar = body['data']?['viewer']?['contributionsCollection']?['contributionCalendar'];
        if (calendar != null) {
          return calendar['weeks'] as List<dynamic>?;
        }
      } else {
        _logger.log('Failed to fetch GraphQL contributions (${response.statusCode}): ${response.body}', type: LogType.error);
      }
    } catch (e) {
      _logger.log('Error fetching contribution calendar: $e', type: LogType.error);
    }
    return null;
  }
}
