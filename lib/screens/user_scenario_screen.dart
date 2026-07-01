import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/domain/entities/system_info.dart';
import 'package:msi_controller/logic/blocs/settings/settings_bloc.dart';
import 'package:msi_controller/logic/blocs/settings/settings_event.dart';
import 'package:msi_controller/logic/blocs/settings/settings_state.dart';
import 'package:msi_controller/domain/repositories/msi_repository.dart';
import 'package:msi_controller/core/di/injection.dart';
import 'package:msi_controller/widgets/glass_container.dart';
import 'package:msi_controller/screens/user_scenario/widgets/user_scenario_telemetry_item.dart';

class UserScenarioScreen extends StatefulWidget {
  const UserScenarioScreen({super.key});

  @override
  State<UserScenarioScreen> createState() => _UserScenarioScreenState();
}

class _UserScenarioScreenState extends State<UserScenarioScreen>
    with AutomaticKeepAliveClientMixin {
  final MsiRepository _repository = getIt<MsiRepository>();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: StreamBuilder<SystemInfo>(
            stream: _repository.systemInfoStream,
            initialData: _repository.lastSystemInfo,
            builder: (context, sysSnapshot) {
              final info = sysSnapshot.data;

              return CustomScrollView(
                slivers: [
                  // Premium Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xxxl,
                        AppSpacing.xxxl,
                        AppSpacing.xxxl,
                        AppSpacing.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                                'User Scenario',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const Spacer(),
                              if (info != null)
                                _buildTelemetryHeader(info, colors),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Select a performance profile to synchronize hardware protocols with your current mission.',
                            style: TextStyle(
                              color: colors.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Applying Status (Only when active)
                  if (state.isPerformanceLoading ||
                      state.isGpuLoading ||
                      state.isFanLoading)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxxl,
                          vertical: AppSpacing.md,
                        ),
                        child: _buildApplyingBanner(state, colors),
                      ),
                    ),

                  // Mode Grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxxl,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _ScenarioCards(state: state),
                    ),
                  ),

                  // Manual Console (Only for User mode)
                  if (state.performanceMode == PerformanceMode.user)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xxxl,
                        AppSpacing.xxxl,
                        AppSpacing.xxxl,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MANUAL PROTOCOL OVERRIDE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: colors.textSecondary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _CustomUserControls(state: state),
                          ],
                        ),
                      ),
                    ),

                  // GPU Console
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xxxl,
                        AppSpacing.xxxl,
                        AppSpacing.xxxl,
                        AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GRAPHICS ARCHITECTURE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: colors.textSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hardware-level GPU mode switching requires a display protocol restart.',
                            style: TextStyle(
                              color: colors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxxl,
                    ),
                    sliver: SliverToBoxAdapter(child: _GpuCards(state: state)),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxxl),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTelemetryHeader(SystemInfo info, AppColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UserScenarioTelemetryItem(
          icon: Icons.thermostat,
          value: '${info.cpuTemperature ?? "--"}°C',
          color: colors.performance,
        ),
        const SizedBox(width: AppSpacing.xl),
        UserScenarioTelemetryItem(
          icon: Icons.bolt,
          value: '${info.cpuUsage ?? "--"}%',
          color: colors.balanced,
        ),
        const SizedBox(width: AppSpacing.xl),
        UserScenarioTelemetryItem(
          icon: Icons.battery_charging_full,
          value: '${info.batteryLevel ?? "--"}%',
          color: colors.success,
        ),
      ],
    );
  }

  Widget _buildApplyingBanner(SettingsState state, AppColors colors) {
    String loadingText = 'SYNCING PROTOCOLS...';
    if (state.isPerformanceLoading) {
      loadingText = 'PUSHING PERFORMANCE CLOCK...';
    } else if (state.isGpuLoading) {
      loadingText = 'SWITCHING GRAPHICS BUS...';
    } else if (state.isFanLoading) {
      loadingText = 'ADJUSTING THERMAL CURVE...';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.performance.withValues(alpha: 0.1),
        borderRadius: AppRadius.smAll,
        border: Border.all(color: colors.performance.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            loadingText,
            style: TextStyle(
              color: colors.performance,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioCards extends StatelessWidget {
  final SettingsState state;
  const _ScenarioCards({required this.state});

  @override
  Widget build(BuildContext context) {
    const cards = [
      (PerformanceMode.extreme, 'PERFORMANCE', Icons.speed),
      (PerformanceMode.balanced, 'BALANCED', Icons.balance),
      (PerformanceMode.silent, 'SILENT', Icons.graphic_eq),
      (PerformanceMode.superBattery, 'BATTERY', Icons.battery_charging_full),
      (PerformanceMode.user, 'CONSOLE', Icons.terminal),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1000
            ? 5
            : (constraints.maxWidth > 600 ? 3 : 2);
        final cardWidth =
            (constraints.maxWidth - ((columns - 1) * AppSpacing.xl)) / columns;

        return Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.xl,
          children: cards.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = state.performanceMode == item.$1;

            return SizedBox(
              width: cardWidth,
              child: AspectRatio(
                aspectRatio: 1.0,
                child: _ModeCard(
                  title: item.$2,
                  icon: item.$3,
                  selected: isSelected,
                  isApplying: isSelected && state.isPerformanceLoading,
                  index: index,
                  onTap: state.isPerformanceLoading
                      ? null
                      : () => context.read<SettingsBloc>().add(
                          SetPerformanceModeEvent(item.$1),
                        ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ModeCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final bool isApplying;
  final int index;
  final VoidCallback? onTap;

  const _ModeCard({
    required this.title,
    required this.icon,
    required this.selected,
    this.isApplying = false,
    required this.index,
    required this.onTap,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> with TickerProviderStateMixin {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovering ? 1.02 : 1.0,
          duration: AppDurations.fast,
          curve: Curves.easeOut,
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: widget.selected
                      ? colors.performance
                      : colors.textSecondary,
                  size: 38,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.selected
                        ? colors.textPrimary
                        : colors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                if (widget.selected) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.performance,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                if (widget.isApplying)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: AppRadius.mdAll,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomUserControls extends StatelessWidget {
  final SettingsState state;
  const _CustomUserControls({required this.state});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ControlRow<PerformanceLevel>(
            label: 'PERFORMANCE LEVEL',
            value: state.performanceLevel,
            items: PerformanceLevel.values,
            labelBuilder: (value) => value.displayName.toUpperCase(),
            onChanged: state.isPerformanceLoading
                ? null
                : (value) {
                    if (value != null) {
                      context.read<SettingsBloc>().add(
                        SetPerformanceLevelEvent(value),
                      );
                    }
                  },
          ),
          const SizedBox(height: AppSpacing.xl),
          _ControlRow<FanMode>(
            label: 'THERMAL PROTOCOL',
            value: state.fanMode,
            items: FanMode.values,
            labelBuilder: (value) => value.displayName.toUpperCase(),
            onChanged: state.isFanLoading
                ? null
                : (value) {
                    if (value != null) {
                      context.read<SettingsBloc>().add(SetFanModeEvent(value));
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class _GpuCards extends StatelessWidget {
  final SettingsState state;
  const _GpuCards({required this.state});

  @override
  Widget build(BuildContext context) {
    const cards = [
      (GpuMode.dynamic, 'DYNAMIC', 'SMART SWITCH', Icons.auto_awesome),
      (GpuMode.discrete, 'DISCRETE', 'MAX POWER', Icons.flash_on),
      (GpuMode.integrated, 'INTEGRATED', 'ECO MODE', Icons.energy_savings_leaf),
      (GpuMode.hybrid, 'SMART', 'INTELLIGENT', Icons.layers),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900 ? 4 : 2;
        final cardWidth =
            (constraints.maxWidth - ((columns - 1) * AppSpacing.xl)) / columns;

        return Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.xl,
          children: cards.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = state.gpuMode == item.$1;

            return SizedBox(
              width: cardWidth,
              child: AspectRatio(
                aspectRatio: 2.2,
                child: _GpuCard(
                  title: item.$2,
                  subtitle: item.$3,
                  icon: item.$4,
                  selected: isSelected,
                  index: index,
                  onTap: state.isGpuLoading
                      ? null
                      : () => context.read<SettingsBloc>().add(
                          SetGpuModeEvent(item.$1),
                        ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _GpuCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final int index;
  final VoidCallback? onTap;

  const _GpuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.index,
    required this.onTap,
  });

  @override
  State<_GpuCard> createState() => _GpuCardState();
}

class _GpuCardState extends State<_GpuCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hover ? 1.02 : 1.0,
          duration: AppDurations.fast,
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  color: widget.selected
                      ? colors.performance
                      : colors.textTertiary,
                  size: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: widget.selected
                              ? colors.textPrimary
                              : colors.textSecondary,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: colors.performance,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlRow<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T value) labelBuilder;
  final ValueChanged<T?>? onChanged;

  const _ControlRow({
    required this.label,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 7,
          child: _StyledDropdown<T>(
            value: value,
            items: items,
            labelBuilder: labelBuilder,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T value) labelBuilder;
  final ValueChanged<T?>? onChanged;
  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return DropdownButtonFormField<T>(
      initialValue: value,
      dropdownColor: const Color(0xFF050510),
      style: TextStyle(
        color: colors.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        fontFamily: 'monospace',
      ),
      iconEnabledColor: colors.performance,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: colors.border.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: colors.performance),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(labelBuilder(item)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
