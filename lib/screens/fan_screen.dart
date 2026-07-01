import 'dart:async';
import 'package:flutter/material.dart';
import 'package:msi_controller/core/di/injection.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/domain/entities/system_info.dart';
import 'package:msi_controller/domain/repositories/msi_repository.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/services/toast_service.dart';
import 'package:msi_controller/screens/fan/widgets/fan_empty_state.dart';
import 'package:msi_controller/screens/fan/widgets/fan_thermal_tips.dart';
import 'package:msi_controller/screens/fan/widgets/fan_header.dart';
import 'package:msi_controller/core/ui/widgets/fan_control_card.dart';

class FanScreen extends StatefulWidget {
  const FanScreen({super.key});

  @override
  State<FanScreen> createState() => _FanScreenState();
}

class _FanScreenState extends State<FanScreen>
    with SingleTickerProviderStateMixin {
  final MsiRepository _repository = getIt<MsiRepository>();
  final Map<int, int> _targetRpms = {};
  final Map<int, bool> _autoModes = {};
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: AppDurations.medium,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
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
        getIt<ToastService>().showError('FAILED TO SET THERMAL PROTOCOL');
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
        getIt<ToastService>().showError('FAILED TO SET ROTATION VELOCITY');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Cooling Hub',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: () => _repository.refreshFanInfo(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'SYNC THERMALS',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<FanInfo>>(
        stream: _repository.fanInfoStream,
        initialData: _repository.lastFanInfo,
        builder: (context, snapshot) {
          final fans = snapshot.data ?? [];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FanHeader(colors: colors),
            const SizedBox(height: AppSpacing.xxxl),

            if (fans.isEmpty)
              FanEmptyState(colors: colors)
            else
              ...fans.asMap().entries.map(
                (entry) => FanControlCard(
                  fan: entry.value,
                  index: entry.key,
                  colors: colors,
                  autoMode: _autoModes[entry.value.fanIndex] ?? entry.value.autoMode,
                  targetRpm: _targetRpms[entry.value.fanIndex] ?? entry.value.targetRpm,
                  onAutoModeToggle: (v) => _setFanAutoMode(entry.value.fanIndex, v),
                  onSpeedChanged: (v) => setState(() => _targetRpms[entry.value.fanIndex] = v),
                ),
              ),

            const SizedBox(height: AppSpacing.xxxl),
            FanThermalTips(colors: colors),
          ],
        ),
      ),
    );
        },
      ),
    );
  }

  // Methods removed during widget extraction
  // _buildFanControlCard and _getFanColor extracted to FanControlCard widget
}
