import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../models/dev_persona.dart';
import '../services/scheduler_service.dart';

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
      appBar: AppBar(title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold))),
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
          const SizedBox(height: 24),
          _buildHeading('Target Configuration'),
          _buildTextField(
            TextEditingController(text: provider.targetBranch),
            'Target Branch (leave empty for default)',
            'e.g. staging, dev',
            onChanged: (v) => provider.setTargetBranch(v),
          ),
          const SizedBox(height: 16),
          _buildMultiRepoConfig(provider),
          const SizedBox(height: 24),
          _buildHeading('Intelligence Persona'),
          _buildPersonaDropdown(provider),
          const SizedBox(height: 32),
          _buildHeading('Professional Workflows'),
          _buildSwitchTile(
            'Multi-Branch & PRs', 
            'Simulate branching and merging lifecycle', 
            provider.enableProWorkflows,
            (v) => provider.toggleProWorkflows(v),
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            'Automated Pull Requests (Auto PR)',
            'Auto-create and merge PRs on feature completion',
            provider.enableAutoPr,
            (v) => provider.toggleAutoPr(v),
          ),
          const SizedBox(height: 32),
          _buildHeading('Smart Schedule'),
          ListTile(
            title: const Text('Working Hours', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${provider.startTime.format(context)} to ${provider.endTime.format(context)}', style: const TextStyle(color: Colors.white60)),
            leading: const Icon(Icons.schedule, color: Colors.orangeAccent),
            trailing: const Icon(Icons.edit, size: 16, color: Colors.white54),
            onTap: () async {
              final start = await showTimePicker(context: context, initialTime: provider.startTime);
              if (start != null) {
                final end = await showTimePicker(context: context, initialTime: provider.endTime);
                if (end != null) {
                  provider.setSchedule(start, end);
                }
              }
            },
          ),
          const SizedBox(height: 24),
          _buildHeading('Simulation Behavior Profile'),
          _buildBehaviorProfileDropdown(provider),
          const SizedBox(height: 32),
          _buildHeading('Simulation Tweaks'),
          _buildSwitchTile('Active Hours Enforcement', 'Simulate human downtime patterns', true, (v) {}),
          _buildSwitchTile('Contextual Delays', 'More advanced human timing', true, (v) {}),
          const SizedBox(height: 32),
          _buildHeading('App Privacy'),
          _buildSwitchTile(
            'Secure PIN Lock', 
            'Protect your streak with a 4-digit PIN', 
            provider.appPin != null,
            (v) {
              if (v) {
                _showPinDialog(context, provider);
              } else {
                provider.setAppPin(null);
              }
            },
          ),
          const SizedBox(height: 32),
          _buildHeading('Account Control'),
          ListTile(
            title: const Text('Synchronize Repository'),
            subtitle: const Text('Manual trigger for full GitHub state sync'),
            leading: const Icon(Icons.sync, color: Colors.blueAccent),
            onTap: () => _showSyncAlert(context),
          ),
          const SizedBox(height: 64),
          const Center(
            child: Text(
              'DevSim Mobile v1.6.0 – Premium Edition\nProfessional Activity Intelligence Core',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 10),
            ),
          )
        ],
      ),
    );
  }

  void _showSyncAlert(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting full repository synchronization...')),
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

  Widget _buildPersonaDropdown(AppProvider provider) {
    return DropdownButtonFormField<DevPersona>(
      value: provider.persona,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
      ),
      dropdownColor: const Color(0xFF1E1B4B),
      items: DevPersona.values.map((p) {
        return DropdownMenuItem(
          value: p,
          child: Text(p.displayName, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: (p) {
        if (p != null) provider.setPersona(p);
      },
    );
  }

  Widget _buildBehaviorProfileDropdown(AppProvider provider) {
    return DropdownButtonFormField<BehaviorProfile>(
      value: provider.behaviorProfile,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
      ),
      dropdownColor: const Color(0xFF1E1B4B),
      items: BehaviorProfile.values.map((p) {
        String label;
        switch (p) {
          case BehaviorProfile.nightOwl:
            label = 'Night Owl (Active 8 PM - 4 AM)';
            break;
          case BehaviorProfile.steady9to5:
            label = 'Steady 9-to-5 (Active 9 AM - 5 PM)';
            break;
          case BehaviorProfile.weekendWarrior:
            label = 'Weekend Warrior (Active Sat/Sun)';
            break;
          case BehaviorProfile.standard:
          default:
            label = 'Standard (Custom working hours)';
        }
        return DropdownMenuItem(
          value: p,
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        );
      }).toList(),
      onChanged: (p) {
        if (p != null) provider.setBehaviorProfile(p);
      },
    );
  }

  Widget _buildMultiRepoConfig(AppProvider provider) {
    final controller = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tracked Repositories',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Add new repository name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  fillColor: Colors.white.withOpacity(0.03),
                  filled: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  provider.addTrackedRepo(name);
                  controller.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            )
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: provider.reposList.map((repo) {
            final isSelected = provider.repo == repo;
            return ChoiceChip(
              label: Text(
                repo,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  provider.selectActiveRepo(repo);
                }
              },
              selectedColor: const Color(0xFF6366F1),
              backgroundColor: Colors.white.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              avatar: isSelected 
                  ? const Icon(Icons.check, size: 14, color: Colors.white) 
                  : InkWell(
                      onTap: () => provider.removeTrackedRepo(repo),
                      child: const Icon(Icons.close, size: 14, color: Colors.white60),
                    ),
            );
          }).toList(),
        )
      ],
    );
  }
}
