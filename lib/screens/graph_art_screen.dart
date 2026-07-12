import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_provider.dart';
import '../services/github_service.dart';
import '../services/graph_art_service.dart';
import '../services/notification_service.dart';

class GraphArtScreen extends StatefulWidget {
  const GraphArtScreen({super.key});

  @override
  State<GraphArtScreen> createState() => _GraphArtScreenState();
}

class _GraphArtScreenState extends State<GraphArtScreen> {
  final _textController = TextEditingController();
  final _github = GitHubService();
  final _artService = GraphArtService();

  double _density = 3.0; // commits per pixel
  bool _isPainting = false;
  int _currentPixel = 0;
  int _totalPixels = 0;
  int _currentCommit = 0;
  int _totalCommits = 0;
  final List<String> _paintLogs = [];
  List<List<int>> _previewGrid = [];

  @override
  void initState() {
    super.initState();
    _textController.text = "HIRE ME";
    _updatePreview();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _updatePreview() {
    setState(() {
      _previewGrid = _artService.generateArtGrid(_textController.text);
    });
  }

  Future<void> _startPainting() async {
    final provider = context.read<AppProvider>();
    final token = provider.token;
    final owner = provider.owner;
    final repo = provider.repo;

    if (token == null || owner == null || repo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect to GitHub and configure a repo on the dashboard first.')),
      );
      return;
    }

    final message = _textController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message to paint.')),
      );
      return;
    }

    final grid = _artService.generateArtGrid(message);
    final targetPixels = _artService.mapGridToDates(grid);

    if (targetPixels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active pixels found. Try other text.')),
      );
      return;
    }

    setState(() {
      _isPainting = true;
      _paintLogs.clear();
      _currentPixel = 0;
      _totalPixels = targetPixels.length;
      _currentCommit = 0;
      _totalCommits = targetPixels.length * _density.toInt();
    });

    _addLog('> Starting Graph Painting for "$message"');
    _addLog('> Repository: $owner/$repo');
    _addLog('> Target Branch: ${provider.targetBranch.isNotEmpty ? provider.targetBranch : "default"}');
    _addLog('> Total Active Pixels: $_totalPixels');
    _addLog('> Target Commits: $_totalCommits');
    _addLog('> Processing paint sequence... please do not close the app.');

    try {
      String? defaultBranch = provider.targetBranch.isNotEmpty ? provider.targetBranch : null;
      if (defaultBranch == null) {
        defaultBranch = await _github.getDefaultBranch(token, owner, repo);
      }

      for (int i = 0; i < targetPixels.length; i++) {
        if (!_isPainting) break;

        final pixel = targetPixels[i];
        final pixelDate = pixel['date'] as DateTime;
        final dateString = pixel['dateString'] as String;
        
        setState(() {
          _currentPixel = i + 1;
        });

        _addLog('> Painting pixel $pathCoords(Date: ${DateFormat('yyyy-MM-dd').format(pixelDate)})');

        for (int c = 0; c < _density.toInt(); c++) {
          if (!_isPainting) break;

          setState(() {
            _currentCommit++;
          });

          final path = 'graph_art/pixel_${dateString.split("T")[0]}_$c.txt';
          final commitMsg = 'style: paint pixel at ${dateString.split("T")[0]} ($c)';
          final fileContent = 'Pixel painted by DevSim Graph Art Generator at $dateString. Sync #$c';

          final success = await _github.createOrUpdateFile(
            token: token,
            owner: owner,
            repo: repo,
            path: path,
            content: fileContent,
            message: commitMsg,
            branch: defaultBranch,
            authorDate: dateString,
            committerDate: dateString,
          );

          if (success) {
            _addLog('  - Sync commit #${c + 1} succeeded.');
          } else {
            _addLog('  - Sync commit #${c + 1} failed. Continuing next pixel.');
          }

          // Delay to prevent GitHub API rate limiting
          await Future.delayed(const Duration(milliseconds: 800));
        }
      }

      if (_isPainting) {
        _addLog('> Graph Art painting session completed successfully!');
        NotificationService().showProgressNotification(
          title: "Graph Art Completed",
          body: "Successfully painted '$message' on your GitHub contributions graph!",
        );
      } else {
        _addLog('> Graph Art painting session aborted by user.');
      }
    } catch (e) {
      _addLog('> Error during painting: $e');
    } finally {
      setState(() {
        _isPainting = false;
      });
      // Refresh the real-time graph
      provider.fetchRealTimeGitHubGraph();
    }
  }

  String get pathCoords => '(${_currentPixel}/${_totalPixels}) ';

  void _addLog(String log) {
    setState(() {
      _paintLogs.insert(0, log);
      if (_paintLogs.length > 100) _paintLogs.removeLast();
    });
  }

  void _stopPainting() {
    setState(() {
      _isPainting = false;
    });
    _addLog('> Stopping painting sequence... waiting for active thread to release.');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Graph Art Generator', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.6, -0.6),
            radius: 1.5,
            colors: [
              Color(0xFF1E1B4B),
              Color(0xFF0F111A),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 110, left: 20, right: 20, bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGlassCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _textController,
                      enabled: !_isPainting,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (_) => _updatePreview(),
                      decoration: InputDecoration(
                        labelText: 'Canvas Message Text',
                        hintText: 'e.g. HIRE ME, GOOGLE, etc.',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.03),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Shade Weight (Commits per Pixel)', style: TextStyle(fontSize: 12, color: Colors.white70)),
                            Text('${_density.toInt()} commits/pixel', style: const TextStyle(fontSize: 12, color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Slider(
                          value: _density,
                          min: 1.0,
                          max: 8.0,
                          divisions: 7,
                          activeColor: const Color(0xFF6366F1),
                          inactiveColor: Colors.white10,
                          onChanged: _isPainting ? null : (v) {
                            setState(() {
                              _density = v;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'LIVE CANVAS PREVIEW',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white60, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              _buildGlassCard(
                padding: const EdgeInsets.all(16),
                child: _buildCanvasPreview(),
              ),
              const SizedBox(height: 24),
              if (_isPainting) ...[
                _buildGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Painting Progress', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('${(_currentCommit / _totalCommits * 100).toInt()}%', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _currentCommit / _totalCommits,
                        backgroundColor: Colors.white10,
                        color: const Color(0xFF10B981),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Text('Pixel $_currentPixel of $_totalPixels | Commit $_currentCommit of $_totalCommits', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isPainting ? _stopPainting : _startPainting,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isPainting ? Colors.redAccent : const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          _isPainting ? 'Abort Painting' : 'Paint Canvas',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'PAINTING LOG CONSOLE',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white60, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              _buildGlassCard(
                padding: const EdgeInsets.all(12),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  child: _paintLogs.isEmpty
                      ? const Center(
                          child: Text('Canvas idle. Ready to paint.', style: TextStyle(color: Colors.white24, fontSize: 11)),
                        )
                      : ListView.builder(
                          itemCount: _paintLogs.length,
                          itemBuilder: (context, idx) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              _paintLogs[idx],
                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildCanvasPreview() {
    if (_previewGrid.isEmpty || _previewGrid[0].isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const Text('Enter message text to preview', style: TextStyle(color: Colors.white24, fontSize: 12)),
      );
    }

    final int width = _previewGrid[0].length;

    return Container(
      height: 100,
      alignment: Alignment.center,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(width, (colIdx) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(7, (rowIdx) {
                  final active = _previewGrid[rowIdx][colIdx] == 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF26A641) : const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }
}
