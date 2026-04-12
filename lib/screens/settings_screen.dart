import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiKeyController.text = context.read<AppProvider>().googleApiKey ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildHeading('Intelligence Engine'),
          const SizedBox(height: 16),
          _buildSwitchTile(
            'Gemini AI Generation', 
            'Use Google AI for realistic code/logs', 
            provider.isAiEnabled,
            (v) => provider.setAiSettings(enabled: v),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            _apiKeyController, 
            'Google API Key (Gemini)', 
            'Enter your Gemini 1.5 API Key',
            onChanged: (v) => provider.setAiSettings(apiKey: v),
          ),
          const SizedBox(height: 32),
          _buildHeading('Simulation settings'),
          _buildSwitchTile('Active Hours Only', 'Downtime simulation enabled', true, (v) {}),
          _buildSwitchTile('Randomize Delays', 'More human-like patterns', true, (v) {}),
          const SizedBox(height: 32),
          _buildHeading('Account'),
          ListTile(
            title: const Text('Reset Application'),
            subtitle: const Text('Clear all secure storage and logs'),
            leading: const Icon(Icons.refresh, color: Colors.orangeAccent),
            onTap: () {
               // Implement reset logic
            },
          ),
          const SizedBox(height: 64),
          const Center(
            child: Text(
              'DevSim Mobile v1.1.0\nExperimental Intelligence Core',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeading(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool val, Function(bool) onChanged) {
    return SwitchListTile(
      value: val,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white60)),
      secondary: const Icon(Icons.auto_awesome, color: Color(0xFF6366F1)),
      activeColor: const Color(0xFF6366F1),
    );
  }
}
