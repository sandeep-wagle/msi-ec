import 'dart:async';
import 'package:flutter/material.dart';
import '../core/di/injection.dart';
import '../core/app_colors.dart';
import '../domain/entities/system_info.dart';
import '../domain/repositories/msi_repository.dart';
import '../services/toast_service.dart';
import '../widgets/msi_card.dart';

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
        if (success) _autoModes[fanIndex] = auto;
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
        if (success) _targetRpms[fanIndex] = rpm;
      });
      if (!success) {
        getIt<ToastService>().showError('Failed to set fan speed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.extension<AppColors>()!;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fan Control',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Control fan speed manually or use auto mode.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 28),
            if (_fans.isEmpty)
              MsiCard(
                padding: const EdgeInsets.all(48),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.air, size: 48, color: Color(0xFF475569)),
                      const SizedBox(height: 16),
                      const Text(
                        'No fans detected',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Make sure msi-ec driver is installed',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._fans.map((fan) => _buildFanControlCard(fan, colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildFanControlCard(FanInfo fan, AppColors colors) {
    final autoMode = _autoModes[fan.fanIndex] ?? fan.autoMode;
    final targetRpm = _targetRpms[fan.fanIndex] ?? fan.targetRpm;
    final minRpm = fan.minRpm ?? 0;
    final maxRpm = fan.maxRpm ?? 6000;
    final percent = maxRpm > 0 ? (fan.currentRpm / maxRpm).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.performance.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.air, size: 22, color: Color(0xFFEB1D24)),
              ),
              const SizedBox(width: 12),
              Text(
                'Fan ${fan.fanIndex + 1}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              _buildAutoToggle(autoMode, fan.fanIndex, colors),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Current: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Text(
                  '${fan.currentRpm} RPM',
                  key: ValueKey(fan.currentRpm),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percent),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: colors.gaugeTrack,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getBarColor(percent, colors),
                  ),
                );
              },
            ),
          ),
          if (!autoMode) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Target: $targetRpm RPM',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFFCBD5E1),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            Slider(
              value: targetRpm.toDouble(),
              min: minRpm.toDouble(),
              max: maxRpm.toDouble(),
              divisions: 100,
              label: '$targetRpm RPM',
              onChanged: (value) {
                setState(() => _targetRpms[fan.fanIndex] = value.round());
              },
              onChangeEnd: (value) {
                _setFanSpeed(fan.fanIndex, value.round());
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$minRpm',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'monospace'),
                ),
                Text(
                  '$maxRpm',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'monospace'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                autoMode ? 'Auto Mode' : 'Manual Mode',
                style: TextStyle(
                  fontSize: 12,
                  color: autoMode ? colors.tempCool : colors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (fan.maxRpm != null)
                Text(
                  'Max: ${fan.maxRpm} RPM',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'monospace'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutoToggle(bool autoMode, int fanIndex, AppColors colors) {
    return GestureDetector(
      onTap: () => _setFanAutoMode(fanIndex, !autoMode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: autoMode
              ? colors.tempCool.withValues(alpha: 0.15)
              : colors.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: autoMode
                ? colors.tempCool.withValues(alpha: 0.3)
                : colors.warning.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: autoMode,
              onChanged: (value) => _setFanAutoMode(fanIndex, value),
              activeTrackColor: colors.tempCool.withValues(alpha: 0.3),
              activeThumbColor: colors.tempCool,
              inactiveTrackColor: colors.warning.withValues(alpha: 0.3),
              inactiveThumbColor: colors.warning,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                autoMode ? 'Auto' : 'Manual',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: autoMode ? colors.tempCool : colors.warning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBarColor(double percent, AppColors colors) {
    if (percent < 0.3) return colors.tempCool;
    if (percent < 0.6) return colors.tempWarm;
    return colors.performance;
  }
}
