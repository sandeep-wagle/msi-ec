import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/entities/system_info.dart';
import '../logic/blocs/settings/settings_bloc.dart';
import '../logic/blocs/settings/settings_event.dart';
import '../logic/blocs/settings/settings_state.dart';

class UserScenarioScreen extends StatefulWidget {
  const UserScenarioScreen({super.key});

  @override
  State<UserScenarioScreen> createState() => _UserScenarioScreenState();
}

class _UserScenarioScreenState extends State<UserScenarioScreen> {
  bool _cpuSoftwareControl = true;
  bool _fanSoftwareControl = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final width = MediaQuery.of(context).size.width;
        final horizontalPadding = width < 900 ? 12.0 : 16.0;
        final titleFontSize = width < 900 ? 32.0 : 40.0;
        final gpuTitleFontSize = width < 900 ? 30.0 : 36.0;
        final compactHeader = width < 1000;
        final isApplying =
            state.isPerformanceLoading ||
            state.isGpuLoading ||
            state.isFanLoading ||
            state.isGpuSwitching;

        String loadingText = 'Applying settings...';
        if (state.isPerformanceLoading) {
          loadingText = 'Applying performance mode...';
        } else if (state.isGpuSwitching || state.isGpuLoading) {
          loadingText = 'Switching GPU mode...';
        } else if (state.isFanLoading) {
          loadingText = 'Applying fan mode...';
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0B0D12),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  runSpacing: 10,
                  spacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'User Scenario',
                      style: TextStyle(
                        color: const Color(0xFFE7E7E7),
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (compactHeader) const SizedBox(width: 0),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Software Control Mode',
                          style: TextStyle(
                            color: Color(0xFF8D8D8D),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'CPU',
                          style: TextStyle(
                            color: Color(0xFFE7E7E7),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Transform.scale(
                          scale: 0.75,
                          child: Switch(
                            value: _cpuSoftwareControl,
                            onChanged: (value) {
                              setState(() => _cpuSoftwareControl = value);
                            },
                            activeColor: const Color(0xFFE53935),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Fan',
                          style: TextStyle(
                            color: Color(0xFFE7E7E7),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Transform.scale(
                          scale: 0.75,
                          child: Switch(
                            value: _fanSoftwareControl,
                            onChanged: (value) {
                              setState(() => _fanSoftwareControl = value);
                            },
                            activeColor: const Color(0xFFE53935),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: isApplying
                      ? Container(
                          key: const ValueKey('scenario-loading'),
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1D23),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0x55E53935)),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFE53935),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  loadingText,
                                  style: const TextStyle(
                                    color: Color(0xFFD7D7D7),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('scenario-ready')),
                ),
                const SizedBox(height: 20),
                _ScenarioCards(state: state),
                if (state.performanceMode == PerformanceMode.user) ...[
                  const SizedBox(height: 18),
                  _CustomUserControls(state: state),
                ],
                const SizedBox(height: 28),
                Text(
                  'GPU Switch',
                  style: TextStyle(
                    color: Color(0xFFE3E3E3),
                    fontSize: gpuTitleFontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose the best GPU mode for your current workload.',
                  style: TextStyle(color: Color(0xFF8E8E8E), fontSize: 16),
                ),
                const SizedBox(height: 14),
                _GpuCards(state: state),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScenarioCards extends StatelessWidget {
  final SettingsState state;
  const _ScenarioCards({required this.state});

  @override
  Widget build(BuildContext context) {
    const cards = [
      (PerformanceMode.extreme, 'Extreme Performance', Icons.speed),
      (PerformanceMode.balanced, 'Balanced', Icons.balance),
      (PerformanceMode.silent, 'Silent', Icons.graphic_eq),
      (
        PerformanceMode.superBattery,
        'Super Battery',
        Icons.battery_charging_full,
      ),
      (PerformanceMode.user, 'Customize', Icons.settings),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        const minCardWidth = 170.0;
        final columns = (constraints.maxWidth / (minCardWidth + spacing))
            .floor()
            .clamp(1, cards.length);
        final cardWidth =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((item) {
            final isSelected = state.performanceMode == item.$1;
            return SizedBox(
              width: cardWidth,
              child: AspectRatio(
                aspectRatio: 1.0,
                child: _ModeCard(
                  title: item.$2,
                  icon: item.$3,
                  selected: isSelected,
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

class _CustomUserControls extends StatelessWidget {
  final SettingsState state;
  const _CustomUserControls({required this.state});

  @override
  Widget build(BuildContext context) {
    final perfValues = PerformanceLevel.values;
    final fanValues = FanMode.values;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF181A20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x55E53935)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Custom User Controls',
            style: TextStyle(
              color: Color(0xFFE7E7E7),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _ControlRow<PerformanceLevel>(
            label: 'Performance Level',
            value: state.performanceLevel,
            items: perfValues,
            labelBuilder: (value) => value.displayName,
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
          const SizedBox(height: 12),
          _ControlRow<FanMode>(
            label: 'Fan Speed',
            value: state.fanMode,
            items: fanValues,
            labelBuilder: (value) => value.displayName,
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
      (
        GpuMode.dynamic,
        'Dynamic',
        'On-Demand GPU switching',
        Icons.auto_awesome,
      ),
      (
        GpuMode.discrete,
        'Discrete',
        'Maximum performance (dGPU)',
        Icons.flash_on,
      ),
      (
        GpuMode.integrated,
        'Integrated',
        'Super battery (iGPU only)',
        Icons.energy_savings_leaf,
      ),
      (GpuMode.hybrid, 'MSI Smart', 'Intelligent Hybrid mode', Icons.layers),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        const minCardWidth = 220.0;
        final columns = (constraints.maxWidth / (minCardWidth + spacing))
            .floor()
            .clamp(1, cards.length);
        final cardWidth =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((item) {
            final isSelected = state.gpuMode == item.$1;
            return SizedBox(
              width: cardWidth,
              child: AspectRatio(
                aspectRatio: 1.75,
                child: _GpuCard(
                  title: item.$2,
                  subtitle: item.$3,
                  icon: item.$4,
                  selected: isSelected,
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

class _ModeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _ModeCard({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = constraints.biggest.shortestSide;
        final iconSize = (shortest * 0.24).clamp(26.0, 52.0);
        final titleSize = (shortest * 0.14).clamp(13.0, 24.0);
        final padding = (shortest * 0.08).clamp(10.0, 16.0);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: selected
                    ? const LinearGradient(
                        colors: [Color(0xAA9A1818), Color(0xAA5A0D0D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF1A1D23), Color(0xFF171A20)],
                      ),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFE53935)
                      : const Color(0xFF2B2F38),
                  width: selected ? 2 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: const Color(0x66E53935),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Icon(icon, color: const Color(0xFFCDCDCD), size: iconSize),
                  SizedBox(height: padding * 0.8),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFFBCBCBC),
                      fontSize: titleSize,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GpuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _GpuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = constraints.biggest.shortestSide;
        final iconSize = (shortest * 0.18).clamp(22.0, 34.0);
        final titleSize = (shortest * 0.12).clamp(13.0, 22.0);
        final subtitleSize = (shortest * 0.075).clamp(10.0, 14.0);
        final padding = (shortest * 0.09).clamp(10.0, 16.0);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: selected
                    ? const LinearGradient(
                        colors: [Color(0xAA9A1818), Color(0xAA5A0D0D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF1A1D23), Color(0xFF171A20)],
                      ),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFE53935)
                      : const Color(0xFF2B2F38),
                  width: selected ? 2 : 1,
                ),
              ),
              padding: EdgeInsets.all(padding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: const Color(0xFFC8C8C8), size: iconSize),
                  SizedBox(height: padding * 0.5),
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFFD3D3D3),
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: const Color(0xFF888888),
                      fontSize: subtitleSize,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFDFDFDF),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _StyledDropdown<T>(
                value: value,
                items: items,
                labelBuilder: labelBuilder,
                onChanged: onChanged,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFDFDFDF),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 8,
              child: _StyledDropdown<T>(
                value: value,
                items: items,
                labelBuilder: labelBuilder,
                onChanged: onChanged,
              ),
            ),
          ],
        );
      },
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
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: const Color(0xFF1D2026),
      style: const TextStyle(color: Color(0xFFE8E8E8), fontSize: 15),
      iconEnabledColor: const Color(0xFFCFCFCF),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1D2026),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF736B6B)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFE53935)),
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
