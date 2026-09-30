import 'package:flutter/material.dart';

// MSI Sound Tune palette — flat charcoal with MSI red accent (no neon).
const kBg = Color(0xFF0B0B0D);
const kPanel = Color(0xFF141416);
const kPanelBorder = Color(0x24FFFFFF);
const kAccent = Color(0xFFE5484D); // MSI red, flat
const kAccentGlow = Color(0x00000000);
const kTextPrimary = Color(0xFFF5F4F0);
const kTextSub = Color(0xFFA1A1AA);

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
