import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class SmartPriorityAppListHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final AppColors colors;

  const SmartPriorityAppListHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'APPLICATION PIPELINE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: colors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 180,
          height: 32,
          child: TextField(
            controller: searchController,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: colors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'FILTER...',
              hintStyle: TextStyle(color: colors.textTertiary.withValues(alpha: 0.5)),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 14,
                color: colors.textTertiary.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: colors.glassBg.withValues(alpha: 0.5),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: AppRadius.smAll,
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: onSearchChanged,
          ),
        ),
      ],
    );
  }
}