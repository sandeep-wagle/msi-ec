import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/widgets/glass_container.dart';
import 'fan_screen.dart';
import 'battery_screen.dart';
import 'settings_screen.dart';
import 'sound_tune_screen.dart';
import 'mystic_light_screen.dart';
import 'lan_manager_screen.dart';
import 'smart_priority_screen.dart';
import 'personal_space_screen.dart';

class FeaturesScreen extends StatefulWidget {
  const FeaturesScreen({super.key});

  @override
  State<FeaturesScreen> createState() => _FeaturesScreenState();
}

class _FeaturesScreenState extends State<FeaturesScreen>
    with AutomaticKeepAliveClientMixin {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final isDark = theme.brightness == Brightness.dark;

    final List<_FeatureItemData> allFeatures = [
      _FeatureItemData(
        title: 'Smart Priority',
        version: '3.2.0.1',
        description:
            'AI-driven resource allocation for creative and gaming applications.',
        icon: Icons.auto_awesome_rounded,
        color: isDark ? colors.performance : const Color(0xFFFF4B2B),
        secondaryColor: isDark
            ? colors.performance.withValues(alpha: 0.5)
            : const Color(0xFFFF416C),
        onTap: () => _navigateTo(context, const SmartPriorityScreen()),
      ),
      _FeatureItemData(
        title: 'Cooling Hub',
        version: '1.0.0.1',
        description:
            'Intelligent fan curve management and real-time thermal analysis.',
        icon: Icons.air_rounded,
        color: isDark ? colors.warning : const Color(0xFFFDC830),
        secondaryColor: isDark
            ? colors.warning.withValues(alpha: 0.5)
            : const Color(0xFFF37335),
        onTap: () => _navigateTo(context, const FanScreen()),
      ),
      _FeatureItemData(
        title: 'Battery Master',
        version: '1.2.0.4',
        description:
            'Configure charging thresholds to maximize battery lifespan.',
        icon: Icons.battery_charging_full_rounded,
        color: isDark ? colors.success : const Color(0xFF11998E),
        secondaryColor: isDark
            ? colors.success.withValues(alpha: 0.5)
            : const Color(0xFF38EF7D),
        onTap: () => _navigateTo(context, const BatteryScreen()),
      ),
      _FeatureItemData(
        title: 'Mystic Light',
        version: '3.0.0.5',
        description: 'Full RGB control with dynamic effects and device sync.',
        icon: Icons.lightbulb_outline_rounded,
        color: isDark ? colors.performance : const Color(0xFF8E2DE2),
        secondaryColor: isDark
            ? colors.performance.withValues(alpha: 0.5)
            : const Color(0xFF4A00E0),
        onTap: () => _navigateTo(context, const MysticLightScreen()),
      ),
      _FeatureItemData(
        title: 'LAN Manager',
        version: '3.0.0.0',
        description: 'Prioritize network traffic for low-latency gaming.',
        icon: Icons.network_check_rounded,
        color: isDark ? colors.balanced : const Color(0xFF2193B0),
        secondaryColor: isDark
            ? colors.balanced.withValues(alpha: 0.5)
            : const Color(0xFF6DD5ED),
        onTap: () => _navigateTo(context, const LanManagerScreen()),
      ),
      _FeatureItemData(
        title: 'Sound Tune',
        version: '2.0.0.5',
        description: 'Enhanced audio processing and AI noise cancellation.',
        icon: Icons.graphic_eq_rounded,
        color: isDark ? colors.balanced : const Color(0xFF00B4DB),
        secondaryColor: isDark
            ? colors.balanced.withValues(alpha: 0.5)
            : const Color(0xFF0083B0),
        onTap: () => _navigateTo(context, const SoundTuneScreen()),
      ),
      _FeatureItemData(
        title: 'Personal Space',
        version: '1.0.0.1',
        description: 'Secure environment for your private notes and documents.',
        icon: Icons.lock_person_rounded,
        color: isDark ? colors.superBattery : const Color(0xFF4568DC),
        secondaryColor: isDark
            ? colors.superBattery.withValues(alpha: 0.5)
            : const Color(0xFFB06AB3),
        onTap: () => _navigateTo(context, const PersonalSpaceScreen()),
      ),
      _FeatureItemData(
        title: 'General Settings',
        version: '2.0.0.2',
        description: 'Control webcam, microphone, and critical system keys.',
        icon: Icons.settings_input_composite_rounded,
        color: isDark ? colors.textSecondary : const Color(0xFF3E5151),
        secondaryColor: isDark
            ? colors.textSecondary.withValues(alpha: 0.5)
            : const Color(0xFFDECBA4),
        onTap: () => _navigateTo(context, const SettingsScreen()),
      ),
    ];

    final filteredFeatures = allFeatures
        .where(
          (f) => f.title.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          final horizontalPadding = isWide ? AppSpacing.xxxl : AppSpacing.xl;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.xxxl,
                    horizontalPadding,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: AppSpacing.md,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 4,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: colors.performance,
                                  borderRadius: AppRadius.xsAll,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                'Feature Sets',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: colors.textPrimary,
                                  letterSpacing: -1.0,
                                ),
                              ),
                            ],
                          ),
                          _buildSearchField(colors, isWide),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Exclusive MSI tools designed for high-fidelity performance optimization.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    mainAxisSpacing: isWide ? AppSpacing.xl : AppSpacing.md,
                    crossAxisSpacing: isWide ? AppSpacing.xl : AppSpacing.md,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = filteredFeatures[index];
                    return _FeatureItem(data: item, index: index);
                  }, childCount: filteredFeatures.length),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xxxl),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchField(AppColors colors, bool isWide) {
    return AnimatedContainer(
      duration: AppDurations.medium,
      width: isWide ? 280 : double.infinity,
      height: 44,
      decoration: BoxDecoration(
        color: colors.surfaceElevated.withValues(alpha: 0.5),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: colors.border.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'SEARCH_SYSTEM_TOOLS...',
          hintStyle: TextStyle(
            color: colors.textTertiary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: colors.textTertiary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: colors.textTertiary,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class _FeatureItemData {
  final String title;
  final String version;
  final String description;
  final IconData icon;
  final Color color;
  final Color secondaryColor;
  final VoidCallback onTap;

  _FeatureItemData({
    required this.title,
    required this.version,
    required this.description,
    required this.icon,
    required this.color,
    required this.secondaryColor,
    required this.onTap,
  });
}

class _FeatureItem extends StatefulWidget {
  final _FeatureItemData data;
  final int index;

  const _FeatureItem({required this.data, required this.index});

  @override
  State<_FeatureItem> createState() => _FeatureItemState();
}

class _FeatureItemState extends State<_FeatureItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.data.onTap,
        child: AnimatedScale(
          scale: _isHovering ? 1.03 : 1.0,
          duration: AppDurations.fast,
          curve: Curves.easeOutCubic,
          child: GlassCard(
            padding: EdgeInsets.zero,
              child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                color: _isHovering
                    ? widget.data.color.withValues(
                        alpha: isDark ? 0.06 : 0.04,
                      )
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: widget.data.color.withValues(
                          alpha: isDark ? 0.14 : 0.1,
                        ),
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Icon(
                        widget.data.icon,
                        color: widget.data.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      widget.data.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v${widget.data.version}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: colors.textTertiary,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: Text(
                        widget.data.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Text(
                          'LAUNCH_MODULE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: widget.data.color,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: widget.data.color,
                          size: 10,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
