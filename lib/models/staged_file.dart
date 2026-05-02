class StagedFile {
  final String path;
  final String content;
  final String prompt;
  final DateTime timestamp;

  StagedFile({
    required this.path,
    required this.content,
    required this.prompt,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'content': content,
    'prompt': prompt,
    'timestamp': timestamp.toIso8601String(),
  };

  factory StagedFile.fromJson(Map<String, dynamic> json) => StagedFile(
    path: json['path'],
    content: json['content'],
    prompt: json['prompt'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}
