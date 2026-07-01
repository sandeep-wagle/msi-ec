import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class AddGameButton extends StatelessWidget {
  final AppColors colors;
  final VoidCallback onTap;

  const AddGameButton({
    super.key,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: colors.border.withValues(alpha: 0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 24, color: Colors.white24),
            SizedBox(height: 4),
            Text(
              'LINK NEW APP',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.white24,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
