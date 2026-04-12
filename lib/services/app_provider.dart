import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'github_service.dart';
import 'logger_service.dart';
import 'scheduler_service.dart';
import 'session_engine.dart';
import 'ai_service.dart';
import '../models/commit_record.dart';

class AppProvider extends ChangeNotifier {
  final GitHubService _github = GitHubService();
  final LoggerService _logger = LoggerService();
  final SessionEngine _engine = SessionEngine();
  final SchedulerService _scheduler = SchedulerService();

  String? _token;
  String? _owner;
  String? _repo;
  bool _isRunning = false;
  SimulationMode _mode = SimulationMode.realistic;
  int _targetCommits = 10;
  int _completedCommits = 0;
  int _failedCommits = 0;
  final List<CommitRecord> _commitHistory = [];
  
  // Premium Features
  bool _enableProWorkflows = true;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  final List<int> _heatmapData = List.filled(28, 0); // 4 weeks of data

  // AI Settings
  String? _googleApiKey;
  bool _isAiEnabled = false;

  String? get token => _token;
  String? get owner => _owner;
  String? get repo => _repo;
  bool get isRunning => _isRunning;
  SimulationMode get mode => _mode;
  int get targetCommits => _targetCommits;
  int get completedCommits => _completedCommits;
  int get failedCommits => _failedCommits;
  List<CommitRecord> get commitHistory => List.unmodifiable(_commitHistory);
  
  bool get enableProWorkflows => _enableProWorkflows;
  TimeOfDay get startTime => _startTime;
  TimeOfDay get endTime => _endTime;
  List<int> get heatmapData => List.unmodifiable(_heatmapData);

  String? get googleApiKey => _googleApiKey;
  bool get isAiEnabled => _isAiEnabled;

  double get successRate {
    final total = _completedCommits + _failedCommits;
    if (total == 0) return 100.0;
    return (_completedCommits / total) * 100;
  }

  Future<void> initialize() async {
    _token = await _github.getToken();
    final prefs = await SharedPreferences.getInstance();
    _googleApiKey = prefs.getString('google_api_key');
    _isAiEnabled = prefs.getBool('is_ai_enabled') ?? false;
    _owner = prefs.getString('last_owner');
    _repo = prefs.getString('last_repo');
    
    // Load Premium Settings
    _enableProWorkflows = prefs.getBool('enable_pro_workflows') ?? true;
    final startHour = prefs.getInt('start_hour') ?? 9;
    final startMin = prefs.getInt('start_min') ?? 0;
    final endHour = prefs.getInt('end_hour') ?? 18;
    final endMin = prefs.getInt('end_min') ?? 0;
    _startTime = TimeOfDay(hour: startHour, minute: startMin);
    _endTime = TimeOfDay(hour: endHour, minute: endMin);
    
    final heatmapString = prefs.getString('heatmap_data');
    if (heatmapString != null) {
      final decoded = jsonDecode(heatmapString) as List<dynamic>;
      for (int i = 0; i < decoded.length && i < 28; i++) {
        _heatmapData[i] = decoded[i] as int;
      }
    }

    notifyListeners();
  }

  Future<void> setSchedule(TimeOfDay start, TimeOfDay end) async {
    _startTime = start;
    _endTime = end;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('start_hour', start.hour);
    await prefs.setInt('start_min', start.minute);
    await prefs.setInt('end_hour', end.hour);
    await prefs.setInt('end_min', end.minute);
    notifyListeners();
  }

  Future<void> toggleProWorkflows(bool enabled) async {
    _enableProWorkflows = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_pro_workflows', enabled);
    notifyListeners();
  }

  void _updateHeatmap() async {
    // Increment today's count (today is the last item in the list)
    _heatmapData[27]++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('heatmap_data', jsonEncode(_heatmapData));
    notifyListeners();
  }

  Future<void> setAiSettings({String? apiKey, bool? enabled}) async {
    final prefs = await SharedPreferences.getInstance();
    if (apiKey != null) {
      _googleApiKey = apiKey;
      await prefs.setString('google_api_key', apiKey);
    }
    if (enabled != null) {
      _isAiEnabled = enabled;
      await prefs.setBool('is_ai_enabled', enabled);
    }
    notifyListeners();
  }

  void setConfig({required String owner, required String repo, required SimulationMode mode, required int target}) async {
    _owner = owner;
    _repo = repo;
    _mode = mode;
    _targetCommits = target;
    _completedCommits = 0;
    _failedCommits = 0;
    _commitHistory.clear();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_owner', owner);
    await prefs.setString('last_repo', repo);
    
    notifyListeners();
  }

  Future<bool> createRepository({required String owner, required String name, required bool isPrivate}) async {
    if (_token == null) return false;
    _logger.log('Creating new repository: $name for $owner...', type: LogType.api);
    final success = await _github.createRepo(_token!, name, isPrivate);
    
    if (success) {
      _logger.log('Repo created successfully. Initializing structure...', type: LogType.success);
      _owner = owner; // Set owner immediately
      
      // Auto-push initial files
      await _github.createOrUpdateFile(
        token: _token!,
        owner: owner,
        repo: name,
        path: 'README.md',
        content: '# $name\n\nGenerated by DevSim Mobile.\n\nAutomated activity simulation active.',
        message: 'Initial commit: README',
      );
      await _github.createOrUpdateFile(
        token: _token!,
        owner: owner,
        repo: name,
        path: '.gitignore',
        content: '# AI Activity Simulation\n*.log\nnode_modules/\n.env\n.DS_Store',
        message: 'Initial commit: .gitignore',
      );
    }
    return success;
  }

  void toggleRunning() {
    _isRunning = !_isRunning;
    if (_isRunning) {
      _logger.log('Pulse Engine ACTIVATED.', type: LogType.success);
      _startSessionLoop();
    } else {
      _logger.log('Pulse Engine DEACTIVATED.', type: LogType.warning);
    }
    notifyListeners();
  }

  Future<void> _startSessionLoop() async {
    while (_isRunning) {
      if (_token == null || _owner == null || _repo == null) break;

      // Calculate how many commits to run in this specific pulse session
      final sessionCommits = _scheduler.calculateSessionCommitCount(
        _mode, 
        _targetCommits - _completedCommits
      );
      
      final actualToRun = (_completedCommits + sessionCommits > _targetCommits) 
        ? (_targetCommits - _completedCommits) 
        : sessionCommits;

      if (actualToRun <= 0) {
        _logger.log('Target goal reached! Pulse complete.', type: LogType.success);
        _isRunning = false;
        notifyListeners();
        break;
      }

      await _engine.runSession(
        token: _token!,
        owner: _owner!,
        repo: _repo!,
        commitCount: actualToRun,
        apiKey: _isAiEnabled ? _googleApiKey : null,
        enableProWorkflows: _enableProWorkflows,
        onProgress: (done) {
          _completedCommits++;
          _updateHeatmap();
          notifyListeners();
        },
        onCommit: (record) {
          _commitHistory.insert(0, record);
          if (_commitHistory.length > 100) _commitHistory.removeLast();
          notifyListeners();
        },
      );

      if (!_isRunning) break;

      final delay = _scheduler.calculateNextDelay(_mode);
      _logger.log('Next session in ${delay.inMinutes} minutes...', type: LogType.info);
      await Future.delayed(delay);
    }
  }

  Future<bool> login(String token) async {
    try {
      final success = await _github.validateToken(token);
      if (success) {
        _token = token;
        await _github.saveToken(token);
        // Also fetch user to set owner
        final info = await _github.getRepoInfo(token, '', ''); // Actually get current user
        // Note: github_service should have a getMe() but we use getRepoInfo carefully
        _logger.log('Auth successful.', type: LogType.success);
        notifyListeners();
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}
