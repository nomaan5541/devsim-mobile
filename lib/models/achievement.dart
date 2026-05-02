import 'package:flutter/material.dart';

class Achievement {
  final String title;
  final String description;
  final int requirement;
  final IconData icon;
  bool isUnlocked;

  Achievement({
    required this.title,
    required this.description,
    required this.requirement,
    required this.icon,
    this.isUnlocked = false,
  });
}
