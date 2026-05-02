import 'dart:math';
import 'github_service.dart';
import 'file_generator.dart';
import 'logger_service.dart';
import 'ai_service.dart';
import '../models/commit_record.dart';
import '../models/dev_persona.dart';

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
    String defaultBranch = 'main',
    String? apiKey,
    bool enableProWorkflows = false,
    DevPersona persona = DevPersona.architect,
    Function(int)? onProgress,
    Function(CommitRecord)? onCommit,
  }) async {
    _logger.log('Session Start: $commitCount pulses scheduled for ${persona.displayName}.', type: LogType.info);

    String currentBranch = defaultBranch;
    bool inFeatureBranch = false;
    int featureCommitCount = 0;
    final List<String> sessionAchievements = [];

    for (int i = 0; i < commitCount; i++) {
      // 1. Pro Workflow Logic: Randomly start a feature branch
      if (enableProWorkflows && !inFeatureBranch && _random.nextDouble() > 0.7) {
        final featureName = _generateFeatureName();
        _logger.log('Pro Workflow: Branching to feature/$featureName', type: LogType.info);
        final branched = await _github.createBranch(token, owner, repo, 'feature/$featureName', defaultBranch);
        if (branched) {
          currentBranch = 'feature/$featureName';
          inFeatureBranch = true;
          featureCommitCount = 0;
        }
      }

      final isNewFile = _random.nextBool();
      final ext = FileGenerator.getRandomExtension();
      String path;
      String content;
      String message;

      if (isNewFile) {
        path = FileGenerator.generateFileName(ext);
        message = _generateMessage('add', path);
        
        if (apiKey != null) {
          _logger.log('Intelligence Engine: Analyzing context ($ext) for $path...', type: LogType.api);
          final aiContent = await _ai.generateContent(
            apiKey: apiKey, 
            prompt: _ai.buildCodePrompt(ext, persona),
            fallbackExt: ext,
          );
          content = aiContent ?? _ai.getTemplateContent(ext);
        } else {
          content = _ai.getTemplateContent(ext);
        }
      } else {
        path = 'src/app_logic.$ext';
        message = _generateMessage('fix', path);
        
        if (apiKey != null) {
          _logger.log('Intelligence Engine: Generating technical analysis fix...', type: LogType.api);
          final aiContent = await _ai.generateContent(
            apiKey: apiKey, 
            prompt: _ai.buildAnalysisPrompt(persona),
            fallbackExt: ext,
          );
          content = aiContent ?? _ai.getTemplateContent(ext);
        } else {
          content = _ai.getTemplateContent(ext);
        }
      }

      final success = await _github.createOrUpdateFile(
        token: token,
        owner: owner,
        repo: repo,
        path: path,
        content: content,
        message: message,
        branch: currentBranch == defaultBranch ? null : currentBranch,
      );

      if (success) {
        if (inFeatureBranch) featureCommitCount++;
        sessionAchievements.add(message);
        
        final record = CommitRecord(
          path: path,
          message: message,
          timestamp: DateTime.now(),
          isSuccess: true,
        );
        onCommit?.call(record);
        onProgress?.call(i + 1);

        // 3. Pro Workflow: Handle PR lifecycle
        if (enableProWorkflows && inFeatureBranch && featureCommitCount >= 2) {
          _logger.log('Pro Workflow: Finalizing feature. Opening Pull Request...', type: LogType.info);
          final prNumber = await _github.createPullRequest(
            token, owner, repo, 
            'Feature: Improvement of $currentBranch',
            'Automated feature implementation by ${persona.displayName}. Full review pending.',
            currentBranch, defaultBranch
          );

          if (prNumber != null) {
            // New: Automated AI Review
            if (apiKey != null) {
               _logger.log('Intelligence Engine: Peer Reviewing PR #$prNumber...', type: LogType.api);
               final review = await _ai.generateContent(
                 apiKey: apiKey, 
                 prompt: _ai.buildReviewPrompt(content)
               );
               if (review != null) {
                 await _github.createPRComment(token, owner, repo, prNumber, review);
               }
            }

            _logger.log('Pro Workflow: PR #$prNumber opened/reviewed. Merging...', type: LogType.success);
            await Future.delayed(const Duration(seconds: 4)); 
            final merged = await _github.mergePullRequest(token, owner, repo, prNumber);
            if (merged) {
              _logger.log('Pro Workflow: PR #$prNumber merged into $defaultBranch.', type: LogType.success);
              currentBranch = defaultBranch;
              inFeatureBranch = false;
            }
          }
        }
      } else {
        _logger.log('Session Sync Error. Terminating pulse.', type: LogType.error);
        break;
      }

      if (i < commitCount - 1) {
        final delaySeconds = _random.nextInt(10) + 5;
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }

    // New: Final Narrative Dev Journal
    if (apiKey != null && sessionAchievements.isNotEmpty) {
      _logger.log('Intelligence Engine: Summarizing daily narrative...', type: LogType.api);
      final journal = await _ai.generateContent(
        apiKey: apiKey, 
        prompt: _ai.buildJournalPrompt(sessionAchievements)
      );
      if (journal != null) {
        final dateStr = DateTime.now().toIso8601String().split('T')[0];
        await _github.createOrUpdateFile(
          token: token,
          owner: owner,
          repo: repo,
          path: 'PULSE_REPORT.md',
          content: '## $dateStr - Simulation Output\n\n$journal\n\n*Generated by ${persona.displayName}*',
          message: 'docs: update narrative dev journal',
        );
      }
    }

    _logger.log('Session pulse completed.', type: LogType.success);
  }

  String _generateFeatureName() {
    final names = ['core-refactor', 'ui-enhancement', 'data-layer', 'network-fix', 'loc-support', 'security-patch'];
    return names[_random.nextInt(names.length)];
  }

  String _generateMessage(String type, String path) {
    final fixMessages = ['refactor: optimize data flow', 'fix: resolve race condition', 'docs: update module overview', 'perf: reduce memory footprint'];
    final addMessages = ['feat: implement $path core', 'init: setup module $path', 'build: configure CI for $path'];
    final list = type == 'fix' ? fixMessages : addMessages;
    return list[_random.nextInt(list.length)];
  }
}
