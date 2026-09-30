import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class GlassBottomNavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const GlassBottomNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class GlassBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<GlassBottomNavDestination> destinations;

  const GlassBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const navHeight = 80.0;
    const sideMargin = AppSpacing.xxs;
    const topRadius = AppRadius.lg;

    return SizedBox(
      height: navHeight + bottomPadding,
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: EdgeInsets.only(
                left: sideMargin,
                right: sideMargin,
                bottom: bottomPadding > 0 ? bottomPadding + 4 : AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF141416)
                    : const Color(0xFFF0F2F5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(topRadius),
                  topRight: Radius.circular(topRadius),
                  bottomLeft: Radius.circular(AppRadius.md),
                  bottomRight: Radius.circular(AppRadius.md),
                ),
                boxShadow: isDark
                    ? AppShadows.bottomNavDark
                    : AppShadows.bottomNavLight,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(topRadius),
                  topRight: Radius.circular(topRadius),
                  bottomLeft: Radius.circular(AppRadius.md),
                  bottomRight: Radius.circular(AppRadius.md),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xxxs),
                      child: Row(
                        children: List.generate(destinations.length, (i) {
                          return Expanded(
                            child: _NavItem(
                              destination: destinations[i],
                              isSelected: selectedIndex == i,
                              onTap: () {
                                if (selectedIndex != i) {
                                  onDestinationSelected(i);
                                }
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final GlassBottomNavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    const accent = Color(0xFFEB1D24);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: isSelected ? 1.0 : 0.95,
        duration: AppDurations.fast,
        curve: Curves.easeOutBack,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? destination.selectedIcon : destination.icon,
              color: isSelected ? accent : colors.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              destination.label,
              style: TextStyle(
                fontSize: AppTypography.labelSmall.fontSize,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? accent : colors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
