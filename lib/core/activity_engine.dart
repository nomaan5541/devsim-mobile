import 'dart:math';

class ActivityEngine {
  static final List<String> _commitMessages = [
    'Refactor internal modules for better scalability',
    'Update documentation and usage examples',
    'Optimize performance in data processing layer',
    'Fix minor bugs in state management',
    'Add unit tests for core utilities',
    'Improve error handling in API client',
    'Clean up unused imports and variables',
    'Sync changes from upstream main',
  ];

  static final List<String> _fileExtensions = ['.dart', '.md', '.txt', '.json'];

  static String generateCommitMessage() {
    return _commitMessages[Random().nextInt(_commitMessages.length)];
  }

  static String generateFilePath() {
    final name = 'mod_${Random().nextInt(1000)}';
    final ext = _fileExtensions[Random().nextInt(_fileExtensions.length)];
    return 'src/$name$ext';
  }

  static String generateContent(String path) {
    final timestamp = DateTime.now().toIso8601String();
    if (path.endsWith('.dart')) {
      return '// Generated at $timestamp\nvoid main() {\n  print("Simulator Active: $path");\n}\n';
    } else if (path.endsWith('.json')) {
      return '{\n  "status": "active",\n  "timestamp": "$timestamp",\n  "file": "$path"\n}';
    } else {
      return '# Activity Log: $path\n\nSimulated update at $timestamp.\n';
    }
  }

  // Helper to determine if we should commit now (simulating human patterns)
  static bool shouldCommitNow() {
    final now = DateTime.now();
    // Less active at night (12 AM - 7 AM)
    if (now.hour < 7) {
      return Random().nextDouble() < 0.15;
    }
    // More active during work hours
    return Random().nextDouble() < 0.6;
  }
}
