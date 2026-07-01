import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/logic/blocs/settings/settings_bloc.dart';
import 'package:msi_controller/logic/blocs/settings/settings_state.dart';
import 'package:msi_controller/screens/battery/widgets/battery_header.dart';
import 'package:msi_controller/screens/battery/widgets/battery_section_title.dart';
import 'package:msi_controller/screens/battery/widgets/battery_health_card.dart';
import 'package:msi_controller/screens/battery/widgets/battery_tip_grid.dart';
import 'package:msi_controller/screens/battery/widgets/charge_limit_card.dart';

class BatteryScreen extends StatefulWidget {
  const BatteryScreen({super.key});

  @override
  State<BatteryScreen> createState() => _BatteryScreenState();
}

class _BatteryScreenState extends State<BatteryScreen>
    with SingleTickerProviderStateMixin {
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
          'Battery Master',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BatteryHeader(colors: colors),
                  const SizedBox(height: AppSpacing.xxxl),

                  BatterySectionTitle(title: 'CHARGE PROTOCOL', colors: colors),
                  const SizedBox(height: AppSpacing.md),
                  ChargeLimitCard(batteryLimit: state.batteryLimit),

                  const SizedBox(height: AppSpacing.xxxl),
                  BatterySectionTitle(
                    title: 'MAINTENANCE ANALYTICS',
                    colors: colors,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  BatteryHealthCard(colors: colors),

                  const SizedBox(height: AppSpacing.xxxl),
                  BatterySectionTitle(title: 'PRO TIPS', colors: colors),
                  const SizedBox(height: AppSpacing.md),
                  BatteryTipGrid(colors: colors),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
