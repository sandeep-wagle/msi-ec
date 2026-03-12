import 'package:flutter/material.dart';
import '../core/di/injection.dart';
import '../services/toast_service.dart';

class MysticLightScreen extends StatefulWidget {
  const MysticLightScreen({super.key});

  @override
  State<MysticLightScreen> createState() => _MysticLightScreenState();
}

class _MysticLightScreenState extends State<MysticLightScreen>
    with SingleTickerProviderStateMixin {
  String _effect = 'Static';
  Color _color = Colors.red;
  double _brightness = 1.0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _effects = [
    'Static',
    'Breathing',
    'Color Cycle',
    'Wave',
    'Flashing',
    'Random',
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Mystic Light',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.lightbulb, color: Colors.redAccent, size: 28),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Control RGB lighting effects on your MSI devices.',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 32),

            // Effect Selection
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lighting Effect',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _effects.map((effect) {
                      final isSelected = _effect == effect;
                      return GestureDetector(
                        onTap: () => setState(() => _effect = effect),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.redAccent
                                : (isDark
                                      ? Colors.white10
                                      : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            effect,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Color Picker
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Color Selection',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: _color,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _color.withValues(alpha: 0.3),
                                blurRadius: 8,
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
                      const SizedBox(width: 16),
                      Column(
                        children: [
                          const Text('Red'),
                          Slider(
                            value: _color.red / 255.0,
                            onChanged: (value) => setState(
                              () => _color = Color.fromARGB(
                                _color.alpha,
                                (value * 255).round(),
                                _color.green,
                                _color.blue,
                              ),
                            ),
                            activeColor: Colors.red,
                          ),
                          const Text('Green'),
                          Slider(
                            value: _color.green / 255.0,
                            onChanged: (value) => setState(
                              () => _color = Color.fromARGB(
                                _color.alpha,
                                _color.red,
                                (value * 255).round(),
                                _color.blue,
                              ),
                            ),
                            activeColor: Colors.green,
                          ),
                          const Text('Blue'),
                          Slider(
                            value: _color.blue / 255.0,
                            onChanged: (value) => setState(
                              () => _color = Color.fromARGB(
                                _color.alpha,
                                _color.red,
                                _color.green,
                                (value * 255).round(),
                              ),
                            ),
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Brightness
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Brightness',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('${(_brightness * 100).round()}%'),
                    ],
                  ),
                  Slider(
                    value: _brightness,
                    onChanged: (value) => setState(() => _brightness = value),
                    activeColor: Colors.redAccent,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Apply RGB settings
                  getIt<ToastService>().showSuccess(
                    'Applied Mystic Light: $_effect effect with brightness ${(_brightness * 100).round()}%',
                  );
                },
                icon: const Icon(Icons.lightbulb),
                label: const Text('Apply Settings'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
