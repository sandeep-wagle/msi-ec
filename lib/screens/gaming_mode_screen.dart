import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:msi_controller/core/di/injection.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/domain/repositories/msi_repository.dart';
import 'package:msi_controller/services/toast_service.dart';
import 'package:msi_controller/core/widgets/app_button.dart';
import 'package:msi_controller/widgets/glass_container.dart';
import 'package:msi_controller/screens/gaming_mode/widgets/gaming_mode_toggle.dart';
import 'package:msi_controller/screens/gaming_mode/widgets/add_game_button.dart';

class _GameEntry {
  final String name;
  final IconData icon;
  final Color iconColor;
  bool enabled = false;
  bool gamingModeOn = false;

  _GameEntry({required this.name, required this.icon, required this.iconColor});
}

class GamingModeScreen extends StatefulWidget {
  const GamingModeScreen({super.key});

  @override
  State<GamingModeScreen> createState() => _GamingModeScreenState();
}

class _GamingModeScreenState extends State<GamingModeScreen>
    with TickerProviderStateMixin {
  final MsiRepository _repository = getIt<MsiRepository>();

  bool _globalGamingMode = false;
  bool _isApplying = false;
  bool _smartDetection = false;
  bool _crosshairOverlay = false;
  Timer? _detectionTimer;
  bool _extremePerf = true;
  bool _gamingAudio = true;
  bool _coolerBoost = true;

  final List<_GameEntry> _games = [
    _GameEntry(
      name: 'HOTKEY LIGHTING',
      icon: Icons.keyboard_rounded,
      iconColor: const Color(0xFFF59E0B),
    ),
    _GameEntry(
      name: 'EPIC GAMES CLIENT',
      icon: Icons.sports_esports_rounded,
      iconColor: const Color(0xFF22C55E),
    ),
    _GameEntry(
      name: 'STEAM VR ENGINE',
      icon: Icons.view_in_ar_rounded,
      iconColor: const Color(0xFF3B82F6),
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
      if (!_globalGamingMode && _smartDetection) {
        debugPrint('Smart Detection: scanning for hardware signatures...');
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
          getIt<ToastService>().showSuccess('GAMING MODE: ACTIVE (OPTIMIZED)');
        } else {
          getIt<ToastService>().showInfo('GAMING MODE: STANDBY (RESTORED)');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _globalGamingMode = !value);
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxxl,
                    AppSpacing.xxxl,
                    AppSpacing.xxxl,
                    AppSpacing.xl,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 24,
                        decoration: BoxDecoration(
                          color: colors.performance,
                          borderRadius: AppRadius.xsAll,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        'Gaming Mode',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      GamingModeToggle(
                        isActive: _globalGamingMode,
                        isApplying: _isApplying,
                        colors: colors,
                        onChanged: _toggleGamingMode,
                      ),
                    ],
                  ),
                ),
              ),

              // Hero Illustration & Main Toggles
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxxl,
                  ),
                  child: GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AUTO-TUNING ENGINE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white24,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'MSI Gaming Mode provides intelligent resource allocation and hardware synchronization to deliver ultimate frame rates and low-latency audio.',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxl),
                              _buildFeatureGrid(colors),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xxxl),
                        const Expanded(
                          flex: 2,
                          child: _GamingHeroIllustration(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Game Profiles Grid
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxxl,
                    AppSpacing.xxxl,
                    AppSpacing.xxxl,
                    AppSpacing.md,
                  ),
                  child: Text(
                    'RECOGNIZED GAME PROFILES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: colors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxxl,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppSpacing.xl,
                    mainAxisSpacing: AppSpacing.xl,
                    childAspectRatio: 2.8,
                  ),
                  delegate: SliverChildListDelegate([
                    ..._games.asMap().entries.map(
                      (entry) =>
                          _buildGameEntry(entry.value, entry.key, colors),
                    ),
                    AddGameButton(colors: colors, onTap: _addGame),
                  ]),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xxxl),
              ),
            ],
          ),
          if (_crosshairOverlay)
            IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: _CrosshairPainter(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(AppColors colors) {
    final features = [
      _FeatureToggleItem(
        'CORE PERFORMANCE',
        'Push hardware to extreme clock speeds',
        _extremePerf,
        colors.performance,
        (v) => setState(() => _extremePerf = v),
      ),
      _FeatureToggleItem(
        'PRO RADAR SCAN',
        'Auto-launch optimizations on game start',
        _smartDetection,
        colors.balanced,
        _toggleSmartDetection,
      ),
      _FeatureToggleItem(
        'TACTICAL OVERLAY',
        'FPS Crosshair and performance telemetry',
        _crosshairOverlay,
        colors.warning,
        (v) => setState(() => _crosshairOverlay = v),
      ),
      _FeatureToggleItem(
        'NAHIMIC ENGINE',
        'Max spatial awareness and voice clarity',
        _gamingAudio,
        colors.balanced,
        (v) => setState(() => _gamingAudio = v),
      ),
      _FeatureToggleItem(
        'COOLER BOOST 5',
        'Forced thermal extraction (MAX RPM)',
        _coolerBoost,
        colors.performance,
        (v) => setState(() => _coolerBoost = v),
      ),
    ];

    return Column(
      children: features.map((f) => _buildFeatureRow(f, colors)).toList(),
    );
  }

  Widget _buildFeatureRow(_FeatureToggleItem item, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            Icons.bolt_rounded,
            size: 14,
            color: item.isOn
                ? item.color
                : colors.textTertiary.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: item.isOn ? colors.textPrimary : colors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  item.description.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: item.isOn,
            activeTrackColor: item.color.withValues(alpha: 0.3),
            activeThumbColor: item.color,
            onChanged: (v) {
              item.onChanged(v);
              if (_globalGamingMode) {
                _toggleGamingMode(true);
              } else {
                _applyFeatureStandalone(item.label, v);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGameEntry(_GameEntry game, int index, AppColors colors) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: game.iconColor.withValues(alpha: 0.1),
              borderRadius: AppRadius.smAll,
              border: Border.all(color: game.iconColor.withValues(alpha: 0.2)),
            ),
            child: Icon(game.icon, color: game.iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  game.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  game.gamingModeOn ? 'SYNCED' : 'UNLINKED',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: game.gamingModeOn
                        ? colors.performance
                        : colors.textTertiary,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showGameSettings(game),
            icon: const Icon(Icons.tune_rounded, size: 18),
            color: colors.textTertiary,
            tooltip: 'Config',
          ),
        ],
      ),
    );
  }

  void _showGameSettings(_GameEntry game) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF050510),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        title: Row(
          children: [
            Icon(game.icon, color: game.iconColor, size: 20),
            const SizedBox(width: 12),
            Text(
              game.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: SwitchListTile(
          title: const Text(
            'AUTO-OPTIMIZE',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'ENGAGE GAMING ENGINE ON LAUNCH',
            style: TextStyle(fontSize: 9, color: Colors.white38),
          ),
          value: game.gamingModeOn,
          activeThumbColor: const Color(0xFFEB1D24),
          onChanged: (v) {
            setState(() => game.gamingModeOn = v);
            Navigator.pop(context);
          },
        ),
        actions: [
          AppButton(
            text: 'DISMISS',
            onPressed: () => Navigator.pop(context),
            isElevated: false,
            isPrimary: false,
            foregroundColor: Colors.white38,
          ),
        ],
      ),
    );
  }

  void _applyFeatureStandalone(String label, bool value) {
    switch (label) {
      case 'COOLER BOOST 5':
        _repository.setCoolerBoost(value);
        break;
      case 'CORE PERFORMANCE':
        _repository.setFeatureEnabled('extreme_perf', value);
        break;
      case 'NAHIMIC ENGINE':
        _repository.setFeatureEnabled('gaming_audio', value);
        break;
    }
  }

  void _addGame() {
    showDialog(
      context: context,
      builder: (_) {
        final nameController = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFF050510),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          title: const Text(
            'LINK APPLICATION',
            style: TextStyle(
              color: Color(0xFFEB1D24),
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          content: TextField(
            controller: nameController,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
            ),
            decoration: const InputDecoration(
              hintText: 'Enter executable name...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            autofocus: true,
          ),
          actions: [
            AppButton(
              text: 'CANCEL',
              onPressed: () => Navigator.pop(context),
              isElevated: false,
              isPrimary: false,
              foregroundColor: Colors.white24,
            ),
            AppButton(
              text: 'ATTACH',
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  setState(() {
                    _games.add(
                      _GameEntry(
                        name: nameController.text.trim().toUpperCase(),
                        icon: Icons.sports_esports_rounded,
                        iconColor: Colors.greenAccent,
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              foregroundColor: const Color(0xFFEB1D24),
            ),
          ],
        );
      },
    );
  }
}

class _GamingHeroIllustration extends StatefulWidget {
  const _GamingHeroIllustration();
  @override
  State<_GamingHeroIllustration> createState() =>
      _GamingHeroIllustrationState();
}

class _GamingHeroIllustrationState extends State<_GamingHeroIllustration>
    with TickerProviderStateMixin {
  late AnimationController _rotateController;
  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: _rotateController,
            child: CustomPaint(
              size: const Size(180, 180),
              painter: _TargetHudPainter(colors.performance),
            ),
          ),
          Icon(
            Icons.sports_esports_rounded,
            size: 64,
            color: colors.performance,
          ),
          const Positioned(
            bottom: 0,
            child: Text(
              'ENGINE READY',
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetHudPainter extends CustomPainter {
  final Color color;
  _TargetHudPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(
      center,
      radius - 20,
      paint..color = color.withValues(alpha: 0.1),
    );
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawLine(
        Offset(
          center.dx + math.cos(angle) * (radius - 10),
          center.dy + math.sin(angle) * (radius - 10),
        ),
        Offset(
          center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius,
        ),
        paint..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
  const _FeatureToggleItem(
    this.label,
    this.description,
    this.isOn,
    this.color,
    this.onChanged,
  );
}
