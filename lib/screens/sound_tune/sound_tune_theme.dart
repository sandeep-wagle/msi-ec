import 'package:flutter/material.dart';

// MSI Nahimic Color Palette (Cyan Theme)
const kBg = Color(0xFF080B12); 
const kPanel = Color(0xFF0D1117); 
const kPanelBorder = Color(0xFF1C222D); 
const kAccent = Color(0xFF00F0FF); // Vibrant Cyan
const kAccentGlow = Color(0x4400F0FF);
const kTextPrimary = Color(0xFFFFFFFF);
const kTextSub = Color(0xFF7F8C9D);

class SoundTuneTheme {
  static const h1 = TextStyle(
    color: kTextPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w900,
    letterSpacing: 8,
  );

  static const h2 = TextStyle(
    color: kTextPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.0,
  );

  static const subText = TextStyle(
    color: kTextSub,
    fontSize: 11,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );
}
