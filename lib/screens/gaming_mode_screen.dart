import 'dart:async';
import 'package:flutter/material.dart';
import '../core/di/injection.dart';
import '../domain/repositories/msi_repository.dart';
import '../services/toast_service.dart';

class _GameEntry {
  final String name;
  final IconData icon;
  final Color iconColor;
  bool enabled = false;
  bool gamingModeOn = false;

  _GameEntry({
    required this.name,
    required this.icon,
    required this.iconColor,
  });
}

class GamingModeScreen extends StatefulWidget {
  const GamingModeScreen({super.key});

  @override
  State<GamingModeScreen> createState() => _GamingModeScreenState();
}

class _GamingModeScreenState extends State<GamingModeScreen> {
  final MsiRepository _repository = getIt<MsiRepository>();

  bool _globalGamingMode = false;
  bool _isApplying = false;
  bool _smartDetection = false;
  bool _crosshairOverlay = false;

  // New: Smart Detection timer
  Timer? _detectionTimer;

  // Per-feature toggles (what gaming mode controls)
  bool _extremePerf = true;
  bool _gamingAudio = true;
  bool _coolerBoost = true;

  final List<_GameEntry> _games = [
    _GameEntry(
      name: 'Hotkey Lighting',
      icon: Icons.keyboard,
      iconColor: Colors.orange,
    ),
    _GameEntry(
      name: 'Client',
      icon: Icons.sports_esports,
      iconColor: Colors.green,
    ),
  ];

  @override
  void dispose() {
    _detectionTimer?.cancel();
    super.dispose();
  }

  void _toggleSmartDetection(bool value) {
    setState(() => _smartDetection = value);
    if (value) {
      _startDetection();
    } else {
      _detectionTimer?.cancel();
    }
  }

  void _startDetection() {
    _detectionTimer?.cancel();
    _detectionTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      // In a real app, we'd check running processes via native bridge
      // For now, we'll simulate detection for known game processes
      if (!_globalGamingMode && _smartDetection) {
        // Logic: if any process in _games is running, prompt or auto-enable
        debugPrint('Smart Detection: scanning for games...');
      }
    });
  }

  Future<void> _toggleGamingMode(bool value) async {
    setState(() {
      _isApplying = true;
      _globalGamingMode = value;
    });

    try {
      await _repository.setGamingMode(
        value,
        perf: _extremePerf,
        audio: _gamingAudio,
        cooler: _coolerBoost,
      );
      if (mounted) {
        if (value) {
          getIt<ToastService>().showSuccess(
            'Gaming Mode enabled — Optimizations applied',
          );
        } else {
          getIt<ToastService>().showInfo(
            'Gaming Mode disabled — System restored',
          );
        }
      }
    } catch (e) {
      // Revert on failure
      if (mounted) setState(() => _globalGamingMode = !value);
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Text(
                      'Gaming Mode',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const Spacer(),
                    // Main Gaming Mode toggle
                    _buildGamingModeToggle(isDark),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.help_outline, size: 18),
                      onPressed: () {},
                      tooltip: 'About Gaming Mode',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Description
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.04)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left description
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MSI Gaming Mode provides auto-tuning function for the game you are playing with the best possible visual and audio lighting setting and brings you a superior gaming experience.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Warning banner
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.4),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.warning_amber,
                                    size: 14,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'The following functions can be set in game customization to turn ON/OFF',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Feature toggles grid
                            _buildFeatureGrid(isDark),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Right illustration
                      Expanded(
                        flex: 2,
                        child: _buildGamingIllustration(isDark),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Game List
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ..._games.map((game) => _buildGameEntry(game, isDark)),
                    // Add Game button
                    _buildAddGameButton(isDark),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_crosshairOverlay)
          IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              painter: _CrosshairPainter(),
            ),
          ),
      ],
    );
  }

  Widget _buildGamingModeToggle(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _globalGamingMode
            ? Colors.red.shade700.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _globalGamingMode ? Colors.red.shade700 : Colors.grey.shade400,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Gaming Mode',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _globalGamingMode ? Colors.red.shade700 : Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          _isApplying
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.red.shade700,
                    ),
                  ),
                )
              : Switch(
                  value: _globalGamingMode,
                  activeThumbColor: Colors.red.shade700,
                  onChanged: _toggleGamingMode,
                ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(bool isDark) {
    final features = [
      _FeatureToggleItem(
        label: 'System Performance',
        description:
            'Extreme Performance mode + powerprofilesctl + free memory',
        isOn: _extremePerf,
        color: Colors.red,
        onChanged: (v) => setState(() => _extremePerf = v),
      ),
      _FeatureToggleItem(
        label: 'Smart Detection',
        description: 'AI: Auto-enable Gaming Mode when a game is launched',
        isOn: _smartDetection,
        color: Colors.greenAccent,
        onChanged: _toggleSmartDetection,
      ),
      _FeatureToggleItem(
        label: 'Crosshair Overlay',
        description: 'Virtual crosshair for better aim in FPS games',
        isOn: _crosshairOverlay,
        color: Colors.lime,
        onChanged: (v) => setState(() => _crosshairOverlay = v),
      ),
      _FeatureToggleItem(
        label: 'MSI Audio Engine / Gaming Audio',
        description: 'Max volume and gaming sound profile initialization',
        isOn: _gamingAudio,
        color: Colors.blueAccent,
        onChanged: (v) => setState(() => _gamingAudio = v),
      ),
      _FeatureToggleItem(
        label: 'Cooler Boost',
        description: 'Engage full fan speed for extreme cooling',
        isOn: _coolerBoost,
        color: Colors.cyan,
        onChanged: (v) => setState(() => _coolerBoost = v),
      ),
    ];

    return Column(
      children: features
          .map(
            (f) => _buildFeatureRow(
              f,
              isDark,
              onChanged: (v) {
                f.onChanged(v);
                if (_globalGamingMode) {
                  _toggleGamingMode(true);
                }
              },
            ),
          )
          .toList(),
    );
  }

  Widget _buildFeatureRow(
    _FeatureToggleItem item,
    bool isDark, {
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: item.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: item.color,
                  ),
                ),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: item.isOn,
              activeThumbColor: item.color,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamingIllustration(bool isDark) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [
            Colors.red.shade900.withValues(alpha: 0.35),
            Colors.purple.shade900.withValues(alpha: 0.2),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow circle
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withValues(alpha: 0.1),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
            Icon(Icons.sports_esports, size: 56, color: Colors.red.shade400),
            // Stars
            Positioned(
              top: 10,
              right: 20,
              child: Icon(
                Icons.star,
                size: 12,
                color: Colors.amber.withValues(alpha: 0.8),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 10,
              child: Icon(
                Icons.flash_on,
                size: 16,
                color: Colors.red.withValues(alpha: 0.7),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              child: Icon(
                Icons.auto_awesome,
                size: 10,
                color: Colors.purple.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameEntry(_GameEntry game, bool isDark) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: game.iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(game.icon, color: game.iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              game.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Settings icon
          InkWell(
            onTap: () => _showGameSettings(game),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.settings,
                size: 14,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Gaming mode indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: game.gamingModeOn
                  ? Colors.red.shade600
                  : Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddGameButton(bool isDark) {
    return GestureDetector(
      onTap: _addGame,
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.black26,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              size: 18,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
            const SizedBox(width: 6),
            Text(
              'Add Game',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGameSettings(_GameEntry game) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: game.iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(game.icon, color: game.iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Text(game.name),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Gaming Mode', style: TextStyle(fontSize: 13)),
              subtitle: const Text(
                'Apply gaming optimizations when this game is running',
                style: TextStyle(fontSize: 11),
              ),
              value: game.gamingModeOn,
              activeThumbColor: Colors.red.shade700,
              onChanged: (v) {
                setState(() => game.gamingModeOn = v);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _addGame() {
    final icons = [
      (Icons.sports_esports, 'Game', Colors.green),
      (Icons.computer, 'App', Colors.blue),
    ];

    showDialog(
      context: context,
      builder: (_) {
        final nameController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Game'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Game or application name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.sports_esports),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  setState(() {
                    _games.add(
                      _GameEntry(
                        name: nameController.text.trim(),
                        icon: icons[0].$1,
                        iconColor: icons[0].$3,
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    const length = 15.0;
    const gap = 5.0;

    // Draw crosshair lines
    canvas.drawLine(
      Offset(center.dx, center.dy - gap),
      Offset(center.dx, center.dy - gap - length),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + gap),
      Offset(center.dx, center.dy + gap + length),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - gap, center.dy),
      Offset(center.dx - gap - length, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + gap, center.dy),
      Offset(center.dx + gap + length, center.dy),
      paint,
    );

    // Draw center dot
    canvas.drawCircle(center, 1, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FeatureToggleItem {
  final String label;
  final String description;
  final bool isOn;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _FeatureToggleItem({
    required this.label,
    required this.description,
    required this.isOn,
    required this.color,
    required this.onChanged,
  });
}
