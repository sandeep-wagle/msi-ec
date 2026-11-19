import 'package:flutter/material.dart';

enum SmartPriorityMode { userPriority, realtime, smartPriority }

class AppEntryData {
  final String name;
  final IconData icon;
  final Color color;
  bool inPriorityList;
  AppEntryData({
    required this.name,
    required this.icon,
    required this.color,
    this.inPriorityList = false,
  });
}