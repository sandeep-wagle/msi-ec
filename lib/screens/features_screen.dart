import 'package:flutter/material.dart';
import '../widgets/msi_card.dart';
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

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0x1AFFFFFF)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const MsiSectionHeader(title: 'Feature Sets'),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.play_circle_outline,
                          color: context.extension<AppColors>()!.performance,
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Manage and open MSI exclusive features.\nFeel free to explore your Linux-powered MSI Center!',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF666666),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildBannerButton('Usage Scenarios', () {}),
                    const SizedBox(width: 12),
                    _buildBannerButton('Settings and History', () {}),
                  ],
                ),
              ],
            ),
          ),

          // Features Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available items',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1A1A1A),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('Refresh All'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GridView.count(
                  crossAxisCount: 4,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.15,
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
                      onTap: () =>
                          _navigateTo(context, const BatteryScreen()),
                    ),
                    _FeatureCard(
                      title: 'General Settings',
                      version: '2.0.0.22',
                      description:
                          'Toggle webcam, microphone, and system keys.',
                      icon: Icons.settings_input_composite,
                      isOpen: true,
                      onTap: () =>
                          _navigateTo(context, const SettingsScreen()),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        side: BorderSide(
          color: isDark
              ? const Color(0x33EB1D24)
              : Colors.black.withValues(alpha: 0.1),
        ),
        foregroundColor:
            isDark ? const Color(0xFF64748B) : const Color(0xFF666666),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.extension<AppColors>()!;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isHovered
              ? colors.surfaceElevated
              : colors.cardBackground,
          border: Border.all(
            color: _isHovered
                ? colors.performance.withValues(alpha: 0.3)
                : colors.border,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(18),
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
                  child: Icon(
                    widget.icon,
                    size: 22,
                    color: colors.performance,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        widget.version,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Text(
                widget.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.isOpen ? widget.onTap : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  backgroundColor: widget.isOpen
                      ? colors.performance.withValues(alpha: 0.1)
                      : null,
                  foregroundColor:
                      widget.isOpen ? colors.performance : const Color(0xFF475569),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  widget.isOpen ? 'Open' : 'Install',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
