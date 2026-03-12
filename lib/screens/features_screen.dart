import 'package:flutter/material.dart';
import '../core/di/injection.dart';
import '../domain/repositories/msi_repository.dart';
import 'fan_screen.dart';
import 'battery_screen.dart';
import 'settings_screen.dart';
import 'sound_tune_screen.dart';
import 'mystic_light_screen.dart';
import 'lan_manager_screen.dart';
import 'smart_priority_screen.dart';
import 'gaming_mode_screen.dart';

class FeaturesScreen extends StatefulWidget {
  const FeaturesScreen({super.key});

  @override
  State<FeaturesScreen> createState() => _FeaturesScreenState();
}

class _FeaturesScreenState extends State<FeaturesScreen>
    with AutomaticKeepAliveClientMixin {
  final MsiRepository _repository = getIt<MsiRepository>();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Feature Sets',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.play_circle_outline,
                          color: Colors.redAccent,
                          size: 24,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildBannerButton('Usage Scenarios', () {}),
                        const SizedBox(width: 16),
                        _buildBannerButton('Settings and History', () {}),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Manage and open MSI exclusive features in this page.\nFeel free to explore your Linux-powered MSI Center!',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available items',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text('Refresh All'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                GridView.count(
                  crossAxisCount: 4,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.1,
                  children: [
                    _FeatureCard(
                      title: 'Smart Priority',
                      version: '3.2023.0413.01',
                      description:
                          'Optimize the user experience for creative applications.',
                      icon: Icons.auto_awesome,
                      isOpen: true,
                      onTap: () =>
                          _navigateTo(context, const SmartPriorityScreen()),
                    ),
                    _FeatureCard(
                      title: 'Gaming Mode',
                      version: '3.2023.0412.01',
                      description:
                          'Provide auto-tuning function for your favorite games.',
                      icon: Icons.gamepad,
                      isOpen: true,
                      onTap: () =>
                          _navigateTo(context, const GamingModeScreen()),
                    ),
                    _FeatureCard(
                      title: 'Cooling Hub',
                      version: '1.0.0.1',
                      description:
                          'Advanced fan control and temperature monitoring.',
                      icon: Icons.air,
                      isOpen: true,
                      onTap: () => _navigateTo(context, const FanScreen()),
                    ),
                    _FeatureCard(
                      title: 'Battery Master',
                      version: '1.2.0.4',
                      description:
                          'Extend battery lifespan with charging limit configurations.',
                      icon: Icons.battery_charging_full,
                      isOpen: true,
                      onTap: () => _navigateTo(context, const BatteryScreen()),
                    ),
                    _FeatureCard(
                      title: 'General Settings',
                      version: '2.0.0.22',
                      description:
                          'Toggle webcam, microphone, and system keys.',
                      icon: Icons.settings_input_composite,
                      isOpen: true,
                      onTap: () => _navigateTo(context, const SettingsScreen()),
                    ),
                    _FeatureCard(
                      title: 'Mystic Light',
                      version: '3.0.0.53',
                      description:
                          'Control lighting effects on your MSI devices (via OpenRGB).',
                      icon: Icons.lightbulb_outline,
                      isOpen: true,
                      onTap: () =>
                          _navigateTo(context, const MysticLightScreen()),
                    ),
                    _FeatureCard(
                      title: 'LAN Manager',
                      version: '3.0.0.04',
                      description:
                          'Network traffic analysis and bandwidth monitoring.',
                      icon: Icons.network_check,
                      isOpen: true,
                      onTap: () =>
                          _navigateTo(context, const LanManagerScreen()),
                    ),
                    _FeatureCard(
                      title: 'Sound Tune',
                      version: '2.0.0.54',
                      description:
                          'AI-powered noise cancellation solution for voice calls.',
                      icon: Icons.graphic_eq,
                      isOpen: true,
                      onTap: () =>
                          _navigateTo(context, const SoundTuneScreen()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerButton(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: Colors.grey),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
            body: screen,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final String title;
  final String version;
  final String description;
  final IconData icon;
  final bool isOpen;
  final VoidCallback? onTap;

  const _FeatureCard({
    required this.title,
    required this.version,
    required this.description,
    required this.icon,
    required this.isOpen,
    this.onTap,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.grey.withValues(alpha: 0.05)
              : Colors.grey.shade50,
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 24,
                    color: isDark ? Colors.grey : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.redAccent,
                        ),
                      ),
                      Text(
                        widget.version,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Text(
                widget.description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: widget.isOpen ? widget.onTap : null,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                  backgroundColor: widget.isOpen
                      ? (isDark ? Colors.white10 : Colors.grey.shade200)
                      : null,
                  side: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Text(
                  widget.isOpen ? 'Open' : 'Install',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isOpen
                        ? (isDark ? Colors.white70 : Colors.black87)
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
