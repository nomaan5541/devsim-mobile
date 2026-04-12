import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../../core/github_api.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _tokenController = TextEditingController();
  final _ownerController = TextEditingController();
  final _repoController = TextEditingController();
  bool _isRunning = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tokenController.text = prefs.getString('github_token') ?? '';
      _ownerController.text = prefs.getString('github_owner') ?? '';
      _repoController.text = prefs.getString('github_repo') ?? '';
      _isRunning = prefs.getBool('is_running') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('github_token', _tokenController.text);
    await prefs.setString('github_owner', _ownerController.text);
    await prefs.setString('github_repo', _repoController.text);
    await prefs.setBool('is_running', _isRunning);
  }

  void _toggleSimulator() async {
    if (_tokenController.text.isEmpty || _ownerController.text.isEmpty || _repoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isRunning = !_isRunning;
    });
    await _saveSettings();

    if (_isRunning) {
      Workmanager().registerPeriodicTask(
        "devsim_task",
        "simulate_activity",
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Simulator Started')),
      );
    } else {
      Workmanager().cancelByUniqueName("devsim_task");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Simulator Stopped')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DevSim Dashboard'),
        actions: [
          IconButton(
            icon: Icon(_isRunning ? Icons.stop_circle : Icons.play_circle, color: _isRunning ? Colors.red : Colors.green),
            onPressed: _toggleSimulator,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 32),
            _buildFormSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isRunning ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isRunning ? Colors.green : Colors.blue, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(_isRunning ? Icons.bolt : Icons.pause, color: _isRunning ? Colors.green : Colors.blue, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isRunning ? 'Activity Simulator Live' : 'Simulator Inactive',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                _isRunning ? 'Background tasks are active' : 'Ready to start simulation',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Column(
      children: [
        _buildTextField(_tokenController, 'GitHub Personal Access Token', true),
        const SizedBox(height: 16),
        _buildTextField(_ownerController, 'GitHub Username / Owner', false),
        const SizedBox(height: 16),
        _buildTextField(_repoController, 'Target Repository Name', false),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveSettings,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Save Configuration'),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
      ),
    );
  }
}
