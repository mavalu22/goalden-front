import 'package:flutter/material.dart';

import '../../goals/screens/goals_screen.dart';
import '../../history/screens/history_screen.dart';
import '../../today/screens/today_screen.dart';
import '../../week/screens/week_screen.dart';

class NavDestination {
  const NavDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.placeholder,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget placeholder;
}

final navDestinations = <NavDestination>[
  const NavDestination(
    label: 'Today',
    icon: Icons.today_outlined,
    activeIcon: Icons.today,
    placeholder: TodayScreen(),
  ),
  const NavDestination(
    label: 'Week',
    icon: Icons.view_week_outlined,
    activeIcon: Icons.view_week,
    placeholder: WeekScreen(),
  ),
  const NavDestination(
    label: 'Goals',
    icon: Icons.star_outline,
    activeIcon: Icons.star,
    placeholder: GoalsScreen(),
  ),
  const NavDestination(
    label: 'History',
    icon: Icons.history,
    activeIcon: Icons.history,
    placeholder: HistoryScreen(),
  ),
];

