import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await context.read<AppProvider>().login(token);

      if (!mounted) return;

      if (success) {
        // Explicit navigation — don't rely on Consumer rebuild
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid token or network error. Check your PAT and internet connection.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unexpected error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final loginMsg = provider.loginMessage;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.bolt, size: 56, color: Colors.white),
              ),
              const SizedBox(height: 28),
              const Text(
                'DevSim Mobile',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Developer Activity Simulator',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amberAccent.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, size: 14, color: Colors.amberAccent),
                    SizedBox(width: 6),
                    Text('500 DAY CHALLENGE READY', style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  ],
                ),
              ),

              if (loginMsg != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          loginMsg,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60, size: 16),
                        onPressed: () => context.read<AppProvider>().clearLoginMessage(),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 48),

              // Token Field
              TextField(
                controller: _tokenController,
                obscureText: true,
                enabled: !_isLoading,
                onChanged: (_) {
                  if (context.read<AppProvider>().loginMessage != null) {
                    context.read<AppProvider>().clearLoginMessage();
                  }
                },
                decoration: InputDecoration(
                  labelText: 'GitHub Personal Access Token',
                  hintText: 'ghp_...',
                  prefixIcon: const Icon(Icons.key_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  errorText: _errorMessage,
                ),
                onSubmitted: (_) => _handleLogin(),
              ),
              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF6366F1).withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Verifying token...', style: TextStyle(fontSize: 16)),
                          ],
                        )
                      : const Text('Connect to GitHub', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),

              // Info note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 14, color: Colors.white38),
                  const SizedBox(width: 6),
                  const Text(
                    'Token stored securely on-device',
                    style: TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  // TODO: open github.com/settings/tokens in a browser
                },
                child: const Text(
                  'How to get a PAT?',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6366F1), decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
