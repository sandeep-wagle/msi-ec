import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class SearchFieldWidget extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final bool isWide;

  const SearchFieldWidget({
    super.key,
    required this.controller,
    this.hintText = 'SEARCH_SYSTEM_TOOLS...',
    required this.onChanged,
    this.onClear,
    this.isWide = false,
  });

  @override
  State<SearchFieldWidget> createState() => _SearchFieldWidgetState();
}

class _SearchFieldWidgetState extends State<SearchFieldWidget> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return AnimatedContainer(
      duration: AppDurations.medium,
      width: widget.isWide ? 280 : double.infinity,
      height: 44,
      decoration: BoxDecoration(
        color: colors.surfaceElevated.withValues(alpha: 0.5),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: colors.border.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: widget.controller,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
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
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: colors.textTertiary,
                  ),
                  onPressed: () {
                    widget.controller.clear();
                    setState(() => _query = '');
                    widget.onChanged('');
                    widget.onClear?.call();
                  },
                )
              : null,
        ),
        onChanged: (v) {
          setState(() => _query = v);
          widget.onChanged(v);
        },
      ),
    );
  }
}