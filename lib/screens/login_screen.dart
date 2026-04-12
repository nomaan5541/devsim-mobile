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
              const SizedBox(height: 48),

              // Token Field
              TextField(
                controller: _tokenController,
                obscureText: true,
                enabled: !_isLoading,
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
