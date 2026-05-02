class WebProject {
  final int day;
  final String name;
  final String path;

  WebProject({
    required this.day,
    required this.name,
    required this.path,
  });

  factory WebProject.fromJson(Map<String, dynamic> json) {
    return WebProject(
      day: json['day'] as int,
      name: json['name'] as String,
      path: json['path'] as String,
    );
  }
}
