import 'dart:math';
import 'github_service.dart';
import 'file_generator.dart';
import 'logger_service.dart';
import 'ai_service.dart';
import '../models/commit_record.dart';

class SessionEngine {
  final GitHubService _github = GitHubService();
  final LoggerService _logger = LoggerService();
  final AiService _ai = AiService();
  final Random _random = Random();

  Future<void> runSession({
    required String token,
    required String owner,
    required String repo,
    required int commitCount,
    String? apiKey,
    Function(int)? onProgress,
    Function(CommitRecord)? onCommit,
  }) async {
    _logger.log('Session Start: $commitCount pulses scheduled.', type: LogType.info);

    for (int i = 0; i < commitCount; i++) {
      final isNewFile = _random.nextBool();
      final ext = FileGenerator.getRandomExtension();
      String path;
      String content;
      String message;

      if (isNewFile) {
        path = FileGenerator.generateFileName(ext);
        message = _generateMessage('add', path);
        
        if (apiKey != null) {
          _logger.log('Intelligence Engine: Analyzing context for $path...', type: LogType.api);
          final aiContent = await _ai.generateContent(
            apiKey: apiKey, 
            prompt: _ai.buildCodePrompt(ext)
          );
          content = aiContent ?? FileGenerator.generateContent(ext);
        } else {
          content = FileGenerator.generateContent(ext);
        }
      } else {
        path = 'src/app_logic.$ext';
        message = _generateMessage('fix', path);
        
        if (apiKey != null) {
          _logger.log('Intelligence Engine: Generating deep analysis/fix...', type: LogType.api);
          final aiContent = await _ai.generateContent(
            apiKey: apiKey, 
            prompt: _ai.buildAnalysisPrompt()
          );
          content = aiContent ?? FileGenerator.generateContent(ext);
        } else {
          content = FileGenerator.generateContent(ext);
        }
      }

      final success = await _github.createOrUpdateFile(
        token: token,
        owner: owner,
        repo: repo,
        path: path,
        content: content,
        message: message,
      );

      if (success) {
        final record = CommitRecord(
          path: path,
          message: message,
          timestamp: DateTime.now(),
          isSuccess: true,
        );
        onCommit?.call(record);
        onProgress?.call(i + 1);
      } else {
        _logger.log('Session Sync Error. Terminating pulse.', type: LogType.error);
        break;
      }

      if (i < commitCount - 1) {
        final delaySeconds = _random.nextInt(15) + 10;
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }

    _logger.log('Session pulse completed.', type: LogType.success);
  }

  String _generateMessage(String type, String path) {
    final fixMessages = ['refactor: optimize data flow', 'fix: resolve race condition', 'docs: update module overview', 'perf: reduce memory footprint'];
    final addMessages = ['feat: implement $path core', 'init: setup module $path', 'build: configure CI for $path'];
    final list = type == 'fix' ? fixMessages : addMessages;
    return list[_random.nextInt(list.length)];
  }
}
