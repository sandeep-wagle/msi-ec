import 'package:flutter/material.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class OverviewActionButton extends StatelessWidget {
  final String label;
  final bool loading;
  final Color color;
  final VoidCallback onTap;

  const OverviewActionButton({
    super.key,
    required this.label,
    required this.loading,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: AppRadius.smAll,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: AppRadius.smAll,
          border: Border.all(color: color.withValues(alpha: 0.3)),
          color: color.withValues(alpha: 0.05),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
        ),
      ),
    );
  }
}
