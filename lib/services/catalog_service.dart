import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/web_project.dart';

class CatalogService {
  List<WebProject> _projects = [];

  Future<void> loadCatalog() async {
    final String response = await rootBundle.loadString('assets/web_projects_manifest.json');
    final data = await json.decode(response) as List;
    _projects = data.map((json) => WebProject.fromJson(json)).toList();
  }

  List<WebProject> get projects => _projects;

  Future<Map<String, dynamic>?> getProjectCode(String projectPath) async {
    // Load individual project JSON to prevent memory crashes
    try {
      final String jsonPath = 'assets/projects/$projectPath.json';
      final String bundleResponse = await rootBundle.loadString(jsonPath);
      return await json.decode(bundleResponse) as Map<String, dynamic>;
    } catch (e) {
      print('Error loading project code for $projectPath: $e');
      return null;
    }
  }

  WebProject getProjectByDay(int day) {
    return _projects.firstWhere((p) => p.day == day, orElse: () => _projects.first);
  }
}
