import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/di/injection.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/services/persistence_service.dart';
import 'package:msi_controller/widgets/glass_container.dart';
import 'package:msi_controller/screens/mystic_light/widgets/mystic_light_apply_button.dart';
import 'package:msi_controller/screens/mystic_light/widgets/mystic_light_color_slider.dart';
import 'package:msi_controller/screens/mystic_light/widgets/effect_card.dart';

class MysticLightScreen extends StatefulWidget {
  const MysticLightScreen({super.key});

  @override
  State<MysticLightScreen> createState() => _MysticLightScreenState();
}

class _MysticLightScreenState extends State<MysticLightScreen>
    with SingleTickerProviderStateMixin {
  String _effect = 'Static';
  Color _color = const Color(0xFFEB1D24);
  double _brightness = 1.0;
  final PersistenceService _storage = getIt<PersistenceService>();

  final List<(String, IconData)> _effects = [
    ('Static', Icons.stop_circle_outlined),
    ('Breathing', Icons.air),
    ('Color Cycle', Icons.loop),
    ('Wave', Icons.waves),
    ('Flashing', Icons.flash_on),
    ('Random', Icons.shuffle),
  ];

  @override
  void initState() {
    super.initState();
    _effect = _storage.loadMysticEffect();
    _color = Color(_storage.loadMysticColor());
    _brightness = _storage.loadMysticBrightness();
  }

  void _save() {
    _storage.saveMysticLight(
      effect: _effect,
      color: _color.toARGB32(),
      brightness: _brightness,
      zone: 0,
    );
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
          'Mystic Light',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxxl,
          AppSpacing.md,
          AppSpacing.xxxl,
          AppSpacing.xxxl,
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
                const Text(
                  'RGB Synchronization',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.lightbulb_outline,
                  color: colors.performance,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Personalize your hardware with dynamic RGB lighting effects.',
              style: TextStyle(color: colors.textTertiary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // Effect Grid
            Text(
              'LIGHTING EFFECTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: colors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 800 ? 6 : 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              children: _effects
                  .map((e) => EffectCard(
                    name: e.$1,
                    icon: e.$2,
                    colors: colors,
                    isSelected: _effect == e.$1,
                    onTap: () {
                      setState(() => _effect = e.$1);
                      _save();
                    },
                  ))
                  .toList(),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Color Selection
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COLOR PALETTE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: colors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: _buildColorControls(colors),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BRIGHTNESS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: colors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: _buildBrightnessControl(colors),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Apply Section
            MysticLightApplyButton(colors: colors),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildColorControls(AppColors colors) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.textPrimary.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Column(
                children: [
                  MysticLightColorSlider(
                    label: 'R',
                    value: _color.r,
                    color: Colors.red,
                    onChanged: (v) => _updateColor(r: v),
                  ),
                  MysticLightColorSlider(
                    label: 'G',
                    value: _color.g,
                    color: Colors.green,
                    onChanged: (v) => _updateColor(g: v),
                  ),
                  MysticLightColorSlider(
                    label: 'B',
                    value: _color.b,
                    color: Colors.blue,
                    onChanged: (v) => _updateColor(b: v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _updateColor({double? r, double? g, double? b}) {
    setState(() {
      _color = Color.fromARGB(
        255,
        ((r ?? _color.r) * 255).round(),
        ((g ?? _color.g) * 255).round(),
        ((b ?? _color.b) * 255).round(),
      );
    });
    _save();
  }

  Widget _buildBrightnessControl(AppColors colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${(_brightness * 100).round()}%',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Slider(
          value: _brightness,
          onChanged: (v) {
            setState(() => _brightness = v);
            _save();
          },
          activeColor: colors.performance,
        ),
      ],
    );
  }
}
