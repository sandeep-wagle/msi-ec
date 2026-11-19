import 'package:flutter/material.dart';

class VaultTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isSecret;
  final int maxLines;

  const VaultTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.isSecret = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isSecret,
      maxLines: maxLines,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        fontFamily: 'monospace',
      ),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(
          color: Colors.white24,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.greenAccent),
        ),
      ),
    );
  }
}