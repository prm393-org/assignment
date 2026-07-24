import 'package:flutter/material.dart';

class ShellDestination {
  const ShellDestination({
    required this.path,
    required this.label,
    required this.icon,
    this.selectedIcon,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
}

/// Center slot in bottom nav — pushes a route instead of switching branch.
class ShellCenterAction {
  const ShellCenterAction({
    required this.label,
    required this.icon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final String path;
}

class NotchedNavItem {
  const NotchedNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;
}
