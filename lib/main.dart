import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'services/app_provider.dart';
import 'services/github_service.dart';
import 'services/session_engine.dart';
import 'services/logger_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/lock_screen.dart';

// import 'services/notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // final notification = NotificationService();
    // await notification.initialize();
    
    final github = GitHubService();
    final session = SessionEngine();
    final logger = LoggerService();

    final token = await github.getToken();
    // In background, we need to handle data fetching/persistence safely
    // For now, this is a placeholder for the periodic worker
    
    logger.log('Background pulse active.', type: LogType.info);
    return true;
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // await NotificationService().initialize();
  
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  final appProvider = AppProvider();
  await appProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appProvider),
      ],
      child: const DevSimApp(),
    ),
  );
}

class DevSimApp extends StatelessWidget {
  const DevSimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevSim Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F1117),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E212D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.token == null) return const LoginScreen();
          if (provider.isLocked) return const LockScreen();
          return const DashboardScreen();
        },
      ),
    );
  }
}
