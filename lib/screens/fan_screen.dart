import 'dart:async';
import 'package:flutter/material.dart';
import '../core/di/injection.dart';
import '../domain/entities/system_info.dart';
import '../domain/repositories/msi_repository.dart';
import '../core/app_colors.dart';
import '../services/toast_service.dart';

class FanScreen extends StatefulWidget {
  const FanScreen({super.key});

  @override
  State<FanScreen> createState() => _FanScreenState();
}

class _FanScreenState extends State<FanScreen>
    with SingleTickerProviderStateMixin {
  final MsiRepository _repository = getIt<MsiRepository>();
  StreamSubscription? _fanInfoSub;
  List<FanInfo> _fans = [];
  final Map<int, int> _targetRpms = {};
  final Map<int, bool> _autoModes = {};
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  DateTime _lastFanUpdate = DateTime.now();
  static const _minUpdateInterval = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    _fanInfoSub = _repository.fanInfoStream.listen((fans) {
      final now = DateTime.now();
      if (now.difference(_lastFanUpdate) < _minUpdateInterval) return;
      _lastFanUpdate = now;
      if (mounted) {
        setState(() {
          _fans = fans;
          for (var fan in fans) {
            _targetRpms[fan.fanIndex] = fan.targetRpm;
            _autoModes[fan.fanIndex] = fan.autoMode;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _fanInfoSub?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _setFanAutoMode(int fanIndex, bool auto) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    final success = await _repository.setFanAutoMode(fanIndex, auto);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _autoModes[fanIndex] = auto;
        }
      });
      if (!success) {
        getIt<ToastService>().showError('Failed to set fan mode');
      }
    }
  }

  Future<void> _setFanSpeed(int fanIndex, int rpm) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    final success = await _repository.setFanSpeed(fanIndex, rpm);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _targetRpms[fanIndex] = rpm;
        }
      });
      if (!success) {
        getIt<ToastService>().showError('Failed to set fan speed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fan Control',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Control fan speed manually or use auto mode.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (_fans.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.air,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No fans detected',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Make sure msi-ec driver is installed',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ..._fans.map((fan) => _buildFanControlCard(fan)),
          ],
        ),
      ),
    );
  }

  Widget _buildFanControlCard(FanInfo fan) {
    final autoMode = _autoModes[fan.fanIndex] ?? fan.autoMode;
    final targetRpm = _targetRpms[fan.fanIndex] ?? fan.targetRpm;
    final minRpm = fan.minRpm ?? 0;
    final maxRpm = fan.maxRpm ?? 6000;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.air,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Fan ${fan.fanIndex + 1}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (autoMode
                                ? Theme.of(
                                    context,
                                  ).extension<AppColors>()!.tempCool
                                : Theme.of(
                                    context,
                                  ).extension<AppColors>()!.warning)
                            .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: autoMode,
                        onChanged: (value) =>
                            _setFanAutoMode(fan.fanIndex, value),
                      ),
                      Text(
                        autoMode ? 'Auto' : 'Manual',
                        style: TextStyle(
                          color: autoMode
                              ? Theme.of(
                                  context,
                                ).extension<AppColors>()!.tempCool
                              : Theme.of(
                                  context,
                                ).extension<AppColors>()!.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Current: '),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Text(
                    '${fan.currentRpm} RPM',
                    key: ValueKey(fan.currentRpm),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!autoMode) ...[
              Text(
                'Target: $targetRpm RPM',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Slider(
                value: targetRpm.toDouble(),
                min: minRpm.toDouble(),
                max: maxRpm.toDouble(),
                divisions: 100,
                label: '$targetRpm RPM',
                onChanged: (value) {
                  setState(() {
                    _targetRpms[fan.fanIndex] = value.round();
                  });
                },
                onChangeEnd: (value) {
                  _setFanSpeed(fan.fanIndex, value.round());
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$minRpm RPM',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    '$maxRpm RPM',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(
                begin: 0,
                end: maxRpm > 0 ? fan.currentRpm / maxRpm : 0,
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getTempColor(
                        maxRpm > 0
                            ? (fan.currentRpm / maxRpm * 100).round()
                            : 0,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getTempColor(int temp) {
    if (temp < 30) return Colors.green;
    if (temp < 60) return Colors.blue;
    if (temp < 80) return Colors.orange;
    return Colors.red;
  }
}
