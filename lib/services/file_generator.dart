import 'dart:math';

class FileGenerator {
  static final Random _random = Random();

  static final Map<String, List<String>> _templates = {
    'py': [
      'def calculate_metrics(data):\n    """Optimize logic for better precision."""\n    return [x * 1.5 for x in data]\n',
      'class UserAuth:\n    def __init__(self, token):\n        self.token = token\n    def validate(self):\n        return len(self.token) > 10\n',
      'import math\n\ndef get_prime_factors(n):\n    factors = []\n    while n % 2 == 0:\n        factors.append(2)\n        n //= 2\n    return factors\n',
    ],
    'md': [
      '# Project Documentation\n\n## Overview\nThis project simulates developer activity to test GitHub APIs.\n\n### Usage\nSet up your PAT in the dashboard.',
      '## API Reference\n\n| Endpoint | Method | Description |\n|---|---|---|\n| /repos | GET | List repositories |\n',
      '# Release Notes - v1.0.$_random\n\n- Fixed minor bugs in scheduler\n- Improved logging system latency\n',
    ],
    'json': [
      '{\n  "status": "ready",\n  "version": "1.0.0",\n  "capabilities": ["auth", "scheduler"]\n}',
      '{\n  "logs": [\n    {"event": "start", "time": "${DateTime.now()}"}\n  ]\n}',
    ],
    'txt': [
      'System log initialized at ${DateTime.now()}\nAll modules standing by.',
      'DEBUG: Commit engine pulse detected.\nINFO: Connection stable.',
    ]
  };

  static String generateContent(String ext) {
    final list = _templates[ext] ?? _templates['txt']!;
    return list[_random.nextInt(list.length)];
  }

  static String getRandomExtension() {
    final exts = ['py', 'md', 'json', 'txt'];
    return exts[_random.nextInt(exts.length)];
  }

  static String generateFileName(String ext) {
    final prefixes = ['util', 'core', 'header', 'service', 'engine', 'data', 'README', 'setup'];
    final prefix = prefixes[_random.nextInt(prefixes.length)];
    final id = _random.nextInt(100);
    return '$prefix$id.$ext';
  }

  static String evolveContent(String oldContent, String ext) {
    final newFragment = generateContent(ext);
    if (ext == 'py') {
      return '$oldContent\n\n# New function added\n$newFragment';
    } else if (ext == 'md') {
      return '$oldContent\n\n### Updated Section\nRefined documentation for clarity.';
    }
    return '$oldContent\n// Updated at ${DateTime.now()}\n';
  }
}
