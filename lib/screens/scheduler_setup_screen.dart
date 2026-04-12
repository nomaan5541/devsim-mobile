import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../services/scheduler_service.dart';

class SchedulerSetupScreen extends StatefulWidget {
  const SchedulerSetupScreen({super.key});

  @override
  State<SchedulerSetupScreen> createState() => _SchedulerSetupScreenState();
}

class _SchedulerSetupScreenState extends State<SchedulerSetupScreen> {
  final _ownerController = TextEditingController();
  final _repoController = TextEditingController();
  int _commitCount = 10;
  SimulationMode _mode = SimulationMode.realistic;
  bool _createNewRepo = false;
  bool _isPrivate = true;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _ownerController.text = provider.owner ?? '';
    _repoController.text = provider.repo ?? '';
    _mode = provider.mode;
    _commitCount = provider.targetCommits;
  }

  Future<void> _startSimulation() async {
    if (_ownerController.text.isEmpty || _repoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Owner and Repo are required')));
      return;
    }

    setState(() => _isBusy = true);

    try {
      final provider = context.read<AppProvider>();
      
      if (_createNewRepo) {
        final created = await provider.createRepository(
          owner: _ownerController.text,
          name: _repoController.text,
          isPrivate: _isPrivate,
        );
        if (!created) {
          setState(() => _isBusy = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Repository creation failed. Check logs.')));
          return;
        }
      }

      provider.setConfig(
        owner: _ownerController.text,
        repo: _repoController.text,
        mode: _mode,
        target: _commitCount,
      );
      
      provider.toggleRunning();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Session')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Target Repository'),
            const SizedBox(height: 16),
            _buildTextField(_ownerController, 'GitHub Owner / Organization'),
            const SizedBox(height: 12),
            _buildTextField(_repoController, 'Repository Name'),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Create New Repository', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Initialize a new repo with README'),
              value: _createNewRepo,
              onChanged: (v) => setState(() => _createNewRepo = v),
              activeColor: const Color(0xFF6366F1),
            ),
            if (_createNewRepo) 
              _buildPrivateToggle(),
            const SizedBox(height: 32),
            _buildSectionTitle('Simulation Parameters'),
            const SizedBox(height: 16),
            _buildModeSelector(),
            const SizedBox(height: 24),
            _buildCommitSlider(),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isBusy ? null : _startSimulation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isBusy 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Initialize Pulse Engine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivateToggle() {
    return Row(
      children: [
        const Text('Private Visibility'),
        const Spacer(),
        Switch(
          value: _isPrivate, 
          onChanged: (v) => setState(() => _isPrivate = v),
          activeColor: Colors.orangeAccent,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white60, letterSpacing: 1.2),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Column(
      children: [
        _buildModeOption(SimulationMode.realistic, 'Realistic', 'Random delays, mirrors human activity patterns.'),
        const SizedBox(height: 12),
        _buildModeOption(SimulationMode.instant, 'Instant', 'High frequency commits for rapid testing.'),
      ],
    );
  }

  Widget _buildModeOption(SimulationMode mode, String title, String subtitle) {
    final isSelected = _mode == mode;
    return InkWell(
      onTap: () => setState(() => _mode = mode),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? const Color(0xFF6366F1) : Colors.white12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Radio<SimulationMode>(
              value: mode,
              groupValue: _mode,
              onChanged: (v) => setState(() => _mode = v!),
              activeColor: const Color(0xFF6366F1),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white60)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCommitSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Commit Target', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('$_commitCount Commits', style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: _commitCount.toDouble(),
          min: 1,
          max: 100,
          divisions: 99,
          activeColor: const Color(0xFF6366F1),
          onChanged: (v) => setState(() => _commitCount = v.toInt()),
        ),
      ],
    );
  }
}
