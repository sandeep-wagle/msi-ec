import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/app_colors.dart';
import '../logic/blocs/settings/settings_bloc.dart';
import '../logic/blocs/settings/settings_event.dart';
import '../logic/blocs/settings/settings_state.dart';
import '../widgets/msi_card.dart';

class BatteryScreen extends StatefulWidget {
  const BatteryScreen({super.key});

  @override
  State<BatteryScreen> createState() => _BatteryScreenState();
}

class _BatteryScreenState extends State<BatteryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.extension<AppColors>()!;

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEB1D24)),
            ),
          );
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Battery Settings',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                MsiCard(
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
                            child: const Icon(
                              Icons.battery_charging_full,
                              size: 22,
                              color: Color(0xFFEB1D24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Charge Limit',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Set maximum battery charge level to extend battery life',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: Text(
                              '${state.batteryLimit}%',
                              key: ValueKey(state.batteryLimit),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFEB1D24),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Slider(
                        value: state.batteryLimit.toDouble(),
                        min: 30,
                        max: 100,
                        divisions: 70,
                        label: '${state.batteryLimit}%',
                        onChanged: (value) {},
                        onChangeEnd: (value) {
                          context
                              .read<SettingsBloc>()
                              .add(SetBatteryLimitEvent(value.round()));
                        },
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '30%',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            '100%',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const MsiSectionHeader(title: 'Battery Tips'),
                const SizedBox(height: 16),
                _buildTipCard(
                  icon: Icons.battery_saver,
                  title: 'Extend Battery Life',
                  description:
                      'Keeping the battery between 20-80% can significantly extend its lifespan.',
                  colors: colors,
                ),
                const SizedBox(height: 10),
                _buildTipCard(
                  icon: Icons.thermostat,
                  title: 'Avoid Extreme Temperatures',
                  description:
                      'High temperatures can degrade battery faster. Keep your laptop cool.',
                  colors: colors,
                ),
                const SizedBox(height: 10),
                _buildTipCard(
                  icon: Icons.electrical_services,
                  title: 'Use Original Charger',
                  description:
                      'Always use the original MSI charger for optimal charging.',
                  colors: colors,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String description,
    required AppColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.performance.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: colors.performance),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
