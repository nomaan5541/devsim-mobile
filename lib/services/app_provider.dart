import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'github_service.dart';
import 'logger_service.dart';
import 'scheduler_service.dart';
import 'session_engine.dart';
import 'ai_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/commit_record.dart';
import '../models/dev_persona.dart';
import '../models/achievement.dart';
import '../models/staged_file.dart';
import '../models/web_project.dart';
import 'catalog_service.dart';
import 'notification_service.dart';

class AppProvider extends ChangeNotifier {
  final GitHubService _github = GitHubService();
  final LoggerService _logger = LoggerService();
  final SessionEngine _engine = SessionEngine();
  final SchedulerService _scheduler = SchedulerService();
  final AiService _ai = AiService();
  final CatalogService _catalog = CatalogService();

  String? _token;
  String? _owner;
  String? _repo;
  bool _isRunning = false;
  SimulationMode _mode = SimulationMode.realistic;
  int _targetCommits = 10;
  int _completedCommits = 0;
  int _failedCommits = 0;
  final List<CommitRecord> _commitHistory = [];
  
  // AI Studio Staging Area
  final List<StagedFile> _stagingArea = [];
  bool _isProcessingBatch = false;
  
  // Premium Features
  bool _enableProWorkflows = true;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  final List<int> _heatmapData = List.filled(28, 0); // 4 weeks of data
  
  // Ultimate Features
  DevPersona _persona = DevPersona.fullstack;
  int _totalLocSimulated = 0;
  int _prsMerged = 0;
  int _totalPulses = 0;
  int _lifetimeFiles = 0;
  
  // 500 Day Challenge
  int _challengeDay = 0;
  int _currentStreak = 0;
  List<Achievement> _achievements = [];
  List<String> _dailyJournal = [];
  List<String> _liveLogs = [];
  String? _appPin;
  bool _isLocked = false;
  bool _isCatalogLoaded = false;

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
  
  DevPersona get persona => _persona;
  int get totalLocSimulated => _totalLocSimulated;
  int get prsMerged => _prsMerged;
  int get totalPulses => _totalPulses;
  int get lifetimeFiles => _lifetimeFiles;

  String? get googleApiKey => _googleApiKey;
  bool get isAiEnabled => _isAiEnabled;
  
  int get challengeDay => _challengeDay;
  int get currentStreak => _currentStreak;
  List<Achievement> get achievements => List.unmodifiable(_achievements);
  List<String> get dailyJournal => List.unmodifiable(_dailyJournal);
  List<String> get liveLogs => List.unmodifiable(_liveLogs);
  String? get appPin => _appPin;
  bool get isLocked => _isLocked;
  List<WebProject> get catalogProjects => _catalog.projects;
  bool get isCatalogLoaded => _isCatalogLoaded;

  DateTime? _tokenExpiry;
  DateTime? get tokenExpiry => _tokenExpiry;
  String? _loginMessage;
  String? get loginMessage => _loginMessage;

  List<List<Map<String, dynamic>>>? _githubContributionsWeeks;
  List<List<Map<String, dynamic>>>? get githubContributionsWeeks => _githubContributionsWeeks;
  bool _isLoadingContributions = false;
  bool get isLoadingContributions => _isLoadingContributions;

  // Offline Suite Configurations
  List<String> _reposList = [];
  String _targetBranch = '';
  bool _enableAutoPr = false;
  BehaviorProfile _behaviorProfile = BehaviorProfile.standard;
  Map<String, int> _localSimulatedHistory = {};

  List<String> get reposList => _reposList;
  String get targetBranch => _targetBranch;
  bool get enableAutoPr => _enableAutoPr;
  BehaviorProfile get behaviorProfile => _behaviorProfile;
  Map<String, int> get localSimulatedHistory => _localSimulatedHistory;

  // Future Graph Planner Configurations
  bool _isPlanActive = false;
  DateTime? _planStartTime;
  DateTime? _planEndTime;
  int _planDays = 0;
  int _planCommitsPerDay = 0;
  int _planCompletedCommits = 0;
  DateTime? _nextScheduledCommitTime;
  Timer? _planTimer;
  Timer? _countdownTimer;

  bool get isPlanActive => _isPlanActive;
  DateTime? get planStartTime => _planStartTime;
  DateTime? get planEndTime => _planEndTime;
  int get planDays => _planDays;
  int get planCommitsPerDay => _planCommitsPerDay;
  int get planCompletedCommits => _planCompletedCommits;
  DateTime? get nextScheduledCommitTime => _nextScheduledCommitTime;

  String get tokenExpiryString {
    if (_tokenExpiry == null) return 'Never';
    return DateFormat('yyyy-MM-dd HH:mm').format(_tokenExpiry!.toLocal());
  }

  void clearLoginMessage() {
    _loginMessage = null;
    notifyListeners();
  }

  // Offline Suite Manipulation Methods
  Future<void> addTrackedRepo(String repoName) async {
    final clean = repoName.trim().replaceAll(RegExp(r'\s+'), '-');
    if (clean.isNotEmpty && !_reposList.contains(clean)) {
      _reposList.add(clean);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tracked_repos', jsonEncode(_reposList));
      notifyListeners();
    }
  }

  Future<void> removeTrackedRepo(String repoName) async {
    if (_reposList.contains(repoName)) {
      _reposList.remove(repoName);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tracked_repos', jsonEncode(_reposList));
      if (_repo == repoName) {
        _repo = _reposList.isNotEmpty ? _reposList.first : null;
        await prefs.setString('last_repo', _repo ?? '');
      }
      notifyListeners();
    }
  }

  Future<void> setTargetBranch(String branch) async {
    _targetBranch = branch.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('target_branch', _targetBranch);
    notifyListeners();
  }

  Future<void> toggleAutoPr(bool enabled) async {
    _enableAutoPr = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_auto_pr', enabled);
    notifyListeners();
  }

  Future<void> setBehaviorProfile(BehaviorProfile profile) async {
    _behaviorProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('behavior_profile', profile.index);
    notifyListeners();
  }

  Future<void> selectActiveRepo(String repoName) async {
    if (_reposList.contains(repoName)) {
      _repo = repoName;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_repo', repoName);
      notifyListeners();
    }
  }

  void _incrementLocalHistoryCount() async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _localSimulatedHistory[todayStr] = (_localSimulatedHistory[todayStr] ?? 0) + 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_simulated_history', jsonEncode(_localSimulatedHistory));
    notifyListeners();
  }

  double get successRate {
    final total = _completedCommits + _failedCommits;
    if (total == 0) return 100.0;
    return (_completedCommits / total) * 100;
  }

  Future<void> initialize() async {
    // Initialize Local Offline Notifications
    await NotificationService().initialize();

    _token = await _github.getToken();
    final expiryStr = await _github.getTokenExpiry();
    if (expiryStr != null) {
      _tokenExpiry = _parseExpiryDate(expiryStr);
    } else {
      _tokenExpiry = null;
    }

    if (_token != null && _tokenExpiry != null) {
      if (DateTime.now().isAfter(_tokenExpiry!)) {
        await logout(reason: 'Your GitHub token has expired. Please connect a new token.');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    _googleApiKey = prefs.getString('google_api_key');
    _isAiEnabled = prefs.getBool('is_ai_enabled') ?? false;
    _owner = prefs.getString('last_owner')?.replaceAll(RegExp(r'\s+'), '-');
    _repo = prefs.getString('last_repo')?.replaceAll(RegExp(r'\s+'), '-');

    // Load Offline Suite Settings
    final reposListString = prefs.getString('tracked_repos');
    if (reposListString != null) {
      final decoded = jsonDecode(reposListString) as List<dynamic>;
      _reposList = decoded.cast<String>();
    } else {
      _reposList = _repo != null && _repo!.isNotEmpty ? [_repo!] : [];
    }
    _targetBranch = prefs.getString('target_branch') ?? '';
    _enableAutoPr = prefs.getBool('enable_auto_pr') ?? false;
    _behaviorProfile = BehaviorProfile.values[prefs.getInt('behavior_profile') ?? BehaviorProfile.standard.index];
    
    final historyString = prefs.getString('local_simulated_history');
    if (historyString != null) {
      final decoded = jsonDecode(historyString) as Map<dynamic, dynamic>;
      _localSimulatedHistory = decoded.cast<String, int>();
    }

    // Load Graph Plan Settings
    _isPlanActive = prefs.getBool('plan_active') ?? false;
    final startTimeStr = prefs.getString('plan_start_time');
    _planStartTime = (startTimeStr != null && startTimeStr.isNotEmpty) ? DateTime.parse(startTimeStr) : null;
    final endTimeStr = prefs.getString('plan_end_time');
    _planEndTime = (endTimeStr != null && endTimeStr.isNotEmpty) ? DateTime.parse(endTimeStr) : null;
    _planDays = prefs.getInt('plan_days') ?? 0;
    _planCommitsPerDay = prefs.getInt('plan_commits_per_day') ?? 0;
    _planCompletedCommits = prefs.getInt('plan_completed_commits') ?? 0;
    final nextCommitStr = prefs.getString('plan_next_commit_time');
    _nextScheduledCommitTime = (nextCommitStr != null && nextCommitStr.isNotEmpty) ? DateTime.parse(nextCommitStr) : null;

    if (_isPlanActive) {
      _startPlanScheduler();
    }
    
    // Load Premium Settings
    _enableProWorkflows = prefs.getBool('enable_pro_workflows') ?? true;
    final startHour = prefs.getInt('start_hour') ?? 9;
    final startMin = prefs.getInt('start_min') ?? 0;
    final endHour = prefs.getInt('end_hour') ?? 18;
    final endMin = prefs.getInt('end_min') ?? 0;
    _startTime = TimeOfDay(hour: startHour, minute: startMin);
    _endTime = TimeOfDay(hour: endHour, minute: endMin);
    
    // Load Ultimate Settings
    final personaIndex = prefs.getInt('persona_index') ?? 0;
    _persona = DevPersona.values[personaIndex];
    _totalLocSimulated = prefs.getInt('total_loc') ?? 0;
    _prsMerged = prefs.getInt('prs_merged') ?? 0;
    _totalPulses = prefs.getInt('total_pulses') ?? 0;
    _lifetimeFiles = prefs.getInt('lifetime_files') ?? 0;

    final heatmapString = prefs.getString('heatmap_data');
    if (heatmapString != null) {
      final decoded = jsonDecode(heatmapString) as List<dynamic>;
      for (int i = 0; i < decoded.length && i < 28; i++) {
        _heatmapData[i] = decoded[i] as int;
      }
    }

    // Load Catalog
    await _catalog.loadCatalog();
    _isCatalogLoaded = true;
    _challengeDay = prefs.getInt('challenge_day') ?? 0;
    _currentStreak = prefs.getInt('current_streak') ?? 0;
    _persona = DevPersona.values[prefs.getInt('persona_index') ?? 0];
    _appPin = prefs.getString('app_pin');
    _isLocked = _appPin != null;
    _loadAchievements();

    if (_token != null && (_tokenExpiry == null || DateTime.now().isBefore(_tokenExpiry!))) {
      // Fetch actual GitHub contributions calendar
      fetchRealTimeGitHubGraph();
    }

    notifyListeners();
  }

  void _loadAchievements() {
    _achievements = [
      Achievement(title: 'Getting Started', description: 'Complete Day 1', requirement: 1, icon: Icons.rocket_launch_rounded),
      Achievement(title: 'Consistency', description: 'Complete 7 Days', requirement: 7, icon: Icons.calendar_today_rounded),
      Achievement(title: 'Habit Former', description: 'Complete 21 Days', requirement: 21, icon: Icons.psychology_rounded),
      Achievement(title: 'One Month', description: 'Complete 30 Days', requirement: 30, icon: Icons.auto_awesome_rounded),
      Achievement(title: 'The Century', description: 'Complete 100 Days', requirement: 100, icon: Icons.emoji_events_rounded),
      Achievement(title: 'Halfway Hero', description: 'Complete 250 Days', requirement: 250, icon: Icons.star_rounded),
      Achievement(title: 'The Legend', description: 'Complete 500 Days', requirement: 500, icon: Icons.workspace_premium_rounded),
    ];
    for (var a in _achievements) {
      if (_challengeDay >= a.requirement) a.isUnlocked = true;
    }
  }

  Future<void> setPersona(DevPersona p) async {
    _persona = p;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('persona_index', p.index);
    notifyListeners();
  }

  Future<void> setAppPin(String? pin) async {
    _appPin = pin;
    _isLocked = pin != null;
    final prefs = await SharedPreferences.getInstance();
    if (pin == null) {
      await prefs.remove('app_pin');
    } else {
      await prefs.setString('app_pin', pin);
    }
    notifyListeners();
  }

  void unlock(String pin) {
    if (_appPin == pin) {
      _isLocked = false;
      notifyListeners();
    }
  }

  void _recordLoc(int count) async {
    _totalLocSimulated += count;
    _totalPulses++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_loc', _totalLocSimulated);
    await prefs.setInt('total_pulses', _totalPulses);
    notifyListeners();
  }

  void _recordSync(int files) async {
    _lifetimeFiles += files;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lifetime_files', _lifetimeFiles);
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
    _owner = owner.trim().replaceAll(RegExp(r'\s+'), '-');
    _repo = repo.trim().replaceAll(RegExp(r'\s+'), '-');
    _mode = mode;
    _targetCommits = target < 10 ? 10 : target; // Enforce minimum 10 commits as requested
    _completedCommits = 0;
    _failedCommits = 0;
    _commitHistory.clear();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_owner', _owner!);
    await prefs.setString('last_repo', _repo!);
    
    notifyListeners();
  }

  Future<String?> generateManualAiContent({
    required String prompt,
    required DevPersona persona,
    required String extension,
  }) async {
    if (_googleApiKey == null) return null;
    
    _logger.log('Studio: Manual Intelligence Request ($extension)...', type: LogType.api);
    
    // Construct a specific prompt for manual studio work
    final fullPrompt = '''Act as a Senior $extension Developer with a ${persona.displayName} style. 
Instruction: $prompt
CRITICAL: Do NOT include any conversation, introductions, or summaries. 
OUTPUT ONLY THE VIRGIN CODE. ZERO PLACEHOLDERS.''';

    return await _ai.generateContent(
      apiKey: _googleApiKey!,
      prompt: fullPrompt,
      fallbackExt: extension,
    );
  }

  List<StagedFile> get stagingArea => List.unmodifiable(_stagingArea);
  bool get isProcessingBatch => _isProcessingBatch;

  void addToStaging(StagedFile file) {
    _stagingArea.add(file);
    _logger.log('Studio: Staged new file ${file.path}', type: LogType.success);
    notifyListeners();
  }

  void removeFromStaging(int index) {
    if (index >= 0 && index < _stagingArea.length) {
      _stagingArea.removeAt(index);
      notifyListeners();
    }
  }

  void clearStaging() {
    _stagingArea.clear();
    notifyListeners();
  }

  Future<void> pushStagingToGitHub(String targetRepo) async {
    if (_stagingArea.isEmpty || _isProcessingBatch) return;
    
    final cleanTargetRepo = targetRepo.trim().replaceAll(RegExp(r'\s+'), '-');
    
    _isProcessingBatch = true;
    notifyListeners();
    
    _logger.log('Studio: Initializing batch push for ${_stagingArea.length} files...', type: LogType.api);
    
    _logger.log('Studio: Validating repository access (Pre-flight)...', type: LogType.api);
    String? defaultBranch = await _github.getDefaultBranch(_token!, _owner!, cleanTargetRepo);
    
    if (defaultBranch == null) {
      _logger.log('Studio: Repository "$cleanTargetRepo" not found under "$_owner". Auto-creating...', type: LogType.warning);
      final actualOwner = await _github.createRepoAndGetOwner(_token!, cleanTargetRepo, false);
      if (actualOwner != null) {
        _owner = actualOwner;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_owner', _owner!);
        _logger.log('Studio: Owner resolved to "$_owner". Waiting for propagation...', type: LogType.success);
        await Future.delayed(const Duration(seconds: 5));
        defaultBranch = await _github.getDefaultBranch(_token!, _owner!, cleanTargetRepo);
      }
      if (defaultBranch == null) {
        _logger.log('Studio: Sync Error: Could not access or create "$cleanTargetRepo". Check token permissions (needs repo scope).', type: LogType.error);
        _isProcessingBatch = false;
        notifyListeners();
        return;
      }
    }

    _logger.log('Studio: Pre-flight Successful. Default branch: $defaultBranch', type: LogType.success);

    int successCount = 0;
    for (var file in _stagingArea) {
      final success = await _github.createOrUpdateFile(
        token: _token!,
        owner: _owner!,
        repo: cleanTargetRepo,
        path: file.path,
        content: file.content,
        message: 'studio: ${file.prompt.length > 30 ? file.prompt.substring(0, 30) : file.prompt}',
        branch: defaultBranch,
      );
      
      if (success) {
        successCount++;
        _totalPulses++;
        _recordSync(1);
      }
      
      // Delay to avoid race conditions and provide "pulse" feel
      await Future.delayed(const Duration(seconds: 2));
    }

    _logger.log('Studio: Batch push complete. $successCount/${_stagingArea.length} files synchronized.', type: LogType.success);
    
    _isProcessingBatch = false;
    _stagingArea.clear();
    notifyListeners();
  }

  Future<bool> createRepository({required String owner, required String name, required bool isPrivate}) async {
    if (_token == null) return false;
    final cleanName = name.trim().replaceAll(RegExp(r'\s+'), '-');
    final cleanOwner = owner.trim().replaceAll(RegExp(r'\s+'), '-');
    
    _logger.log('Creating new repository: $cleanName for $cleanOwner...', type: LogType.api);
    final success = await _github.createRepo(_token!, cleanName, isPrivate);
    
    if (success) {
      _logger.log('Repo created. Waiting for GitHub propagation (3s)...', type: LogType.info);
      await Future.delayed(const Duration(seconds: 3)); // Fix for 404 race condition
      
      _logger.log('Initializing repository structure...', type: LogType.api);
      _owner = cleanOwner;
      _repo = cleanName;
      
      // Auto-push initial files
      await _github.createOrUpdateFile(
        token: _token!,
        owner: cleanOwner,
        repo: cleanName,
        path: 'README.md',
        content: '# $cleanName\n\nGenerated by DevSim Mobile.\n\nAutomated activity simulation active.',
        message: 'Initial commit: README',
      );
      await _github.createOrUpdateFile(
        token: _token!,
        owner: cleanOwner,
        repo: cleanName,
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
    await checkTokenExpiry();
    if (_token == null) return;

    _logger.log('Pre-flight check: Validating repository access...', type: LogType.api);
    String? defaultBranch = await _github.getDefaultBranch(_token!, _owner!, _repo!);
    
    if (defaultBranch == null) {
      _logger.log('Repository "$_repo" not found under "$_owner". Auto-creating...', type: LogType.warning);
      final actualOwner = await _github.createRepoAndGetOwner(_token!, _repo!, false);
      if (actualOwner != null) {
        _owner = actualOwner;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_owner', _owner!);
        _logger.log('Owner resolved to "$_owner". Waiting for GitHub propagation...', type: LogType.success);
        await Future.delayed(const Duration(seconds: 5));
        defaultBranch = await _github.getDefaultBranch(_token!, _owner!, _repo!);
      }
      if (defaultBranch == null) {
        _logger.log('Sync Error: Could not access or create "$_repo". Check token permissions (needs repo scope).', type: LogType.error);
        _isRunning = false;
        notifyListeners();
        return;
      }
    }

    _logger.log('Sync Successful. Default branch: $defaultBranch', type: LogType.success);

    while (_isRunning) {
      await checkTokenExpiry();
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
        
        // Offline Progress Notification
        NotificationService().showProgressNotification(
          title: "Goal Reached",
          body: "Successfully pushed target commits to $_repo.",
        );
        
        notifyListeners();
        break;
      }

      await _engine.runSession(
        token: _token!,
        owner: _owner!,
        repo: _repo!,
        commitCount: actualToRun,
        defaultBranch: _targetBranch.isNotEmpty ? _targetBranch : defaultBranch,
        apiKey: _isAiEnabled ? _googleApiKey : null,
        enableProWorkflows: _enableAutoPr || _enableProWorkflows,
        persona: _persona,
        onProgress: (done) {
          _completedCommits++;
          _updateHeatmap();
          _recordLoc(35); // Estimated 35 lines per commit
          _recordSync(1); // One more file processed
          _incrementLocalHistoryCount();
          notifyListeners();
        },
        onCommit: (record) {
          _commitHistory.insert(0, record);
          if (_commitHistory.length > 100) _commitHistory.removeLast();
          notifyListeners();
        },
      );

      if (!_isRunning) break;

      final delay = _scheduler.calculateNextDelay(
        _mode, 
        _startTime, 
        _endTime,
        profile: _behaviorProfile,
      );
      final delayMsg = delay.inMinutes > 0 
        ? '${delay.inMinutes} minutes' 
        : '${delay.inSeconds} seconds';
      _logger.log('Next session in $delayMsg...', type: LogType.info);
      await Future.delayed(delay);
    }
  }

  Future<bool> login(String token) async {
    try {
      _loginMessage = null;
      final success = await _github.validateToken(token);
      if (success) {
        _token = token;
        await _github.saveToken(token);
        
        final expiryStr = await _github.getTokenExpiry();
        if (expiryStr != null) {
          _tokenExpiry = _parseExpiryDate(expiryStr);
        } else {
          _tokenExpiry = null;
        }

        final user = await _github.getCurrentUser(token);
        if (user != null) {
          _owner = user['login'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_owner', _owner!);
          _logger.log('Auth successful. Identity: $_owner', type: LogType.success);
        }
        
        // Load the actual real-time GitHub graph data
        fetchRealTimeGitHubGraph();
        
        notifyListeners();
      }
      return success;
    } catch (e) {
      _logger.log('Login error: $e', type: LogType.error);
      return false;
    }
  }

  Future<void> logout({String? reason}) async {
    _token = null;
    _owner = null;
    _repo = null;
    _tokenExpiry = null;
    _githubContributionsWeeks = null;
    if (_isRunning) {
      _isRunning = false;
    }
    await _github.saveToken('');
    await _github.saveTokenExpiry(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_owner');
    await prefs.remove('last_repo');
    _loginMessage = reason;
    _logger.log('Logged out. Reason: ${reason ?? "User initiated"}', type: LogType.warning);
    notifyListeners();
  }

  DateTime? _parseExpiryDate(String expiryStr) {
    try {
      final cleaned = expiryStr.replaceAll(' UTC', '').trim();
      return DateTime.parse(cleaned);
    } catch (e) {
      return null;
    }
  }

  Future<void> checkTokenExpiry() async {
    if (_token == null) return;
    final expiryStr = await _github.getTokenExpiry();
    if (expiryStr != null) {
      final expiry = _parseExpiryDate(expiryStr);
      if (expiry != null) {
        final now = DateTime.now();
        if (now.isAfter(expiry)) {
          await logout(reason: 'Your GitHub token has expired. Please enter a new token to continue.');
        } else {
          final difference = expiry.difference(now);
          final prefs = await SharedPreferences.getInstance();
          final lastNotifiedExpiry = prefs.getString('last_notified_expiry') ?? '';
          
          String? thresholdKey;
          if (difference.inHours <= 1) {
            thresholdKey = '1h';
          } else if (difference.inDays <= 1) {
            thresholdKey = '1d';
          } else if (difference.inDays <= 3) {
            thresholdKey = '3d';
          }

          if (thresholdKey != null && lastNotifiedExpiry != thresholdKey) {
            await prefs.setString('last_notified_expiry', thresholdKey);
            NotificationService().showExpiryWarning(daysLeft: difference.inDays);
          }
        }
      }
    }
  }

  Future<void> fetchRealTimeGitHubGraph() async {
    if (_token == null) return;
    
    await checkTokenExpiry();
    if (_token == null) return;

    _isLoadingContributions = true;
    notifyListeners();

    try {
      final weeksData = await _github.getContributionCalendar(_token!);
      if (weeksData != null) {
        final List<List<Map<String, dynamic>>> parsedWeeks = [];
        for (var week in weeksData) {
          final contributionDays = week['contributionDays'] as List<dynamic>;
          final List<Map<String, dynamic>> parsedDays = [];
          for (var day in contributionDays) {
            parsedDays.add({
              'count': day['contributionCount'] as int,
              'date': day['date'] as String,
              'color': day['color'] as String,
            });
          }
          parsedWeeks.add(parsedDays);
        }
        _githubContributionsWeeks = parsedWeeks;
      }
    } catch (e) {
      _logger.log('Error parsing contribution calendar: $e', type: LogType.error);
    } finally {
      _isLoadingContributions = false;
      notifyListeners();
    }
  }

  Future<void> setChallengeDay(int day) async {
    _challengeDay = day;
    // Calculate streak logic (simplified for now: if they commit, streak increases)
    _currentStreak++; 
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('challenge_day', day);
    await prefs.setInt('current_streak', _currentStreak);
    
    _loadAchievements();
    notifyListeners();
  }

  Future<void> commitCatalogProject(WebProject project) async {
    if (_token == null || _owner == null || _repo == null) {
      _logger.log('Catalog: Auth required to commit project.', type: LogType.error);
      return;
    }

    _logger.log('Catalog: Syncing Bundled Code for Project #${project.day} (${project.name})...', type: LogType.api);
    
    final projectCode = await _catalog.getProjectCode(project.path);
    
    if (projectCode == null || projectCode.isEmpty) {
      _logger.log('Catalog: Error: Project code not found in bundle for ${project.name}.', type: LogType.error);
      return;
    }

    _logger.log('Catalog: Found ${projectCode.length} files in bundle. Starting pulse...', type: LogType.info);

    int committedCount = 0;
    for (var entry in projectCode.entries) {
      final fileName = entry.key;
      final content = entry.value as String;
      
      String message;
      switch (_persona) {
        case DevPersona.architect:
          message = 'refactor(${project.name}): implement $fileName with architectural best practices';
          break;
        case DevPersona.bugFixer:
          message = 'fix(${project.name}): optimize $fileName for robustness and performance';
          break;
        case DevPersona.hacker:
          message = 'feat(${project.name}): lightning pulse $fileName';
          break;
        case DevPersona.fullstack:
        default:
          message = 'feat(${project.name}): add $fileName';
      }
      
      final success = await _github.createOrUpdateFile(
        token: _token!,
        owner: _owner!,
        repo: _repo!,
        path: '${project.name}/$fileName',
        content: content,
        message: message,
      );
      
      if (success) {
        committedCount++;
        _completedCommits++;
        _recordSync(1);
        final log = '[$fileName] Pushed with ${_persona.displayName} style.';
        _liveLogs.insert(0, log);
        if (_liveLogs.length > 50) _liveLogs.removeLast();
        
        _commitHistory.insert(0, CommitRecord(
          path: '${project.name}/$fileName',
          message: message,
          timestamp: DateTime.now(),
          isSuccess: true,
        ));
        notifyListeners();
      }
      
      await Future.delayed(const Duration(seconds: 1));
    }

    if (_challengeDay < project.day) {
      await setChallengeDay(project.day);
      _dailyJournal.insert(0, 'Day ${project.day}: Built "${project.name}" using ${_persona.displayName} persona. Integrated ${committedCount} modules.');
    }
    
    _logger.log('Catalog: Project #${project.day} ($committedCount files) synchronized successfully.', type: LogType.success);
    notifyListeners();
  }

  Future<void> requestPermissions() async {
    _logger.log('System: Requesting background and storage permissions...', type: LogType.info);
    
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.notification,
      Permission.ignoreBatteryOptimizations,
    ].request();
    
    if (statuses[Permission.storage]!.isGranted) {
      _logger.log('System: Storage access GRANTED.', type: LogType.success);
    }
    if (statuses[Permission.ignoreBatteryOptimizations]!.isGranted) {
      _logger.log('System: Background activity GRANTED.', type: LogType.success);
    }
    
    notifyListeners();
  }

  // Future Graph Planner Scheduler Logic
  Future<void> startGraphPlan(int days, int commitsPerDay) async {
    _isPlanActive = true;
    _planStartTime = DateTime.now();
    _planEndTime = _planStartTime!.add(Duration(days: days));
    _planDays = days;
    _planCommitsPerDay = commitsPerDay;
    _planCompletedCommits = 0;
    
    _calculateNextScheduledCommit();
    await _savePlanState();
    _startPlanScheduler();
    notifyListeners();
  }
  
  Future<void> cancelGraphPlan() async {
    _isPlanActive = false;
    _planStartTime = null;
    _planEndTime = null;
    _planDays = 0;
    _planCommitsPerDay = 0;
    _planCompletedCommits = 0;
    _nextScheduledCommitTime = null;
    
    _planTimer?.cancel();
    _countdownTimer?.cancel();
    await _savePlanState();
    notifyListeners();
  }

  void _calculateNextScheduledCommit() {
    if (!_isPlanActive) return;
    
    final now = DateTime.now();
    final todaySlots = _scheduler.calculateScheduledTimesForDay(
      commitsCount: _planCommitsPerDay,
      start: _startTime,
      end: _endTime,
      relativeTo: now,
    );

    var nextSlot = _scheduler.getNextUpcomingSlot(todaySlots, now);
    
    if (nextSlot == null) {
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowSlots = _scheduler.calculateScheduledTimesForDay(
        commitsCount: _planCommitsPerDay,
        start: _startTime,
        end: _endTime,
        relativeTo: tomorrow,
      );
      if (tomorrowSlots.isNotEmpty) {
        nextSlot = tomorrowSlots.first;
      }
    }
    
    _nextScheduledCommitTime = nextSlot;
  }

  void _startPlanScheduler() {
    _planTimer?.cancel();
    _countdownTimer?.cancel();
    if (!_isPlanActive || _nextScheduledCommitTime == null) return;

    final now = DateTime.now();
    final delay = _nextScheduledCommitTime!.difference(now);

    if (delay.isNegative || delay.inSeconds <= 0) {
      _executePlanCommit();
    } else {
      _planTimer = Timer(delay, () {
        _executePlanCommit();
      });
      _startCountdownTimer();
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    if (!_isPlanActive) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  Future<void> _executePlanCommit() async {
    if (!_isPlanActive) return;

    _logger.log('[Planner] Triggering scheduled commit...', type: LogType.info);
    
    if (_token != null && _owner != null && _repo != null) {
      final path = 'src/graph_plan_sync.txt';
      final success = await _github.createOrUpdateFile(
        token: _token!,
        owner: _owner!,
        repo: _repo!,
        path: path,
        content: 'Graph planner automatic sync at ${DateTime.now().toIso8601String()}',
        message: 'style: graph filler scheduled update',
        branch: _targetBranch.isNotEmpty ? _targetBranch : null,
      );
      
      if (success) {
        _planCompletedCommits++;
        _completedCommits++;
        _updateHeatmap();
        _recordLoc(35);
        _recordSync(1);
        _incrementLocalHistoryCount();
        _logger.log('[Planner] Scheduled commit successfully pushed!', type: LogType.success);
        
        NotificationService().showProgressNotification(
          title: "Graph Planner Commit Succeeded",
          body: "Completed commit $_planCompletedCommits under your active plan.",
        );
      } else {
        _logger.log('[Planner] Scheduled commit failed. Retrying next slot.', type: LogType.error);
      }
    }

    if (_planEndTime != null && DateTime.now().isAfter(_planEndTime!)) {
      _logger.log('[Planner] Graph Plan finished successfully!', type: LogType.success);
      NotificationService().showProgressNotification(
        title: "Graph Planner Finished",
        body: "Your active graph filler plan has successfully ended.",
      );
      await cancelGraphPlan();
    } else {
      _calculateNextScheduledCommit();
      await _savePlanState();
      _startPlanScheduler();
      notifyListeners();
    }
  }

  Future<void> _savePlanState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('plan_active', _isPlanActive);
    await prefs.setString('plan_start_time', _planStartTime?.toIso8601String() ?? '');
    await prefs.setString('plan_end_time', _planEndTime?.toIso8601String() ?? '');
    await prefs.setInt('plan_days', _planDays);
    await prefs.setInt('plan_commits_per_day', _planCommitsPerDay);
    await prefs.setInt('plan_completed_commits', _planCompletedCommits);
    await prefs.setString('plan_next_commit_time', _nextScheduledCommitTime?.toIso8601String() ?? '');
  }

  @override
  void dispose() {
    _planTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
