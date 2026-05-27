import 'package:flutter/material.dart';
import '../core/di/injection.dart';
import '../core/app_colors.dart';
import '../services/toast_service.dart';
import '../widgets/msi_card.dart';

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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _effects = [
    'Static', 'Breathing', 'Color Cycle', 'Wave', 'Flashing', 'Random',
  ];

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

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Mystic Light', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(width: 12),
                Icon(Icons.lightbulb, color: colors.performance, size: 26),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Control RGB lighting effects on your MSI devices.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 28),

            MsiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MsiSectionHeader(title: 'Lighting Effect'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _effects.map((effect) {
                      final isSelected = _effect == effect;
                      return GestureDetector(
                        onTap: () => setState(() => _effect = effect),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.performance
                                : colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? colors.performance
                                  : colors.border,
                            ),
                          ),
                          child: Text(
                            effect,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF94A3B8),
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            MsiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MsiSectionHeader(title: 'Color Selection'),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: _color,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: _color.withValues(alpha: 0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Preview',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildColorSlider('R', Colors.red, _color.red / 255.0, (v) {
                            setState(() => _color = Color.fromARGB(
                              _color.alpha,
                              (v * 255).round(),
                              _color.green,
                              _color.blue,
                            ));
                          }),
                          _buildColorSlider('G', Colors.green, _color.green / 255.0, (v) {
                            setState(() => _color = Color.fromARGB(
                              _color.alpha,
                              _color.red,
                              (v * 255).round(),
                              _color.blue,
                            ));
                          }),
                          _buildColorSlider('B', Colors.blue, _color.blue / 255.0, (v) {
                            setState(() => _color = Color.fromARGB(
                              _color.alpha,
                              _color.red,
                              _color.green,
                              (v * 255).round(),
                            ));
                          }),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            MsiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const MsiSectionHeader(title: 'Brightness'),
                      Text(
                        '${(_brightness * 100).round()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          color: Color(0xFFEB1D24),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _brightness,
                    onChanged: (value) => setState(() => _brightness = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  getIt<ToastService>().showSuccess(
                    'Applied Mystic Light: $_effect effect with brightness ${(_brightness * 100).round()}%',
                  );
                },
                icon: const Icon(Icons.lightbulb, size: 18),
                label: const Text('Apply Settings'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSlider(
    String label,
    Color color,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 12,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: Slider(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            min: 0,
            max: 1,
          ),
        ),
      ],
    );
  }
}
