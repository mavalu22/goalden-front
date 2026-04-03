import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../today/screens/today_screen.dart';

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
  NavDestination(
    label: 'Today',
    icon: Icons.today_outlined,
    activeIcon: Icons.today,
    placeholder: TodayScreen(),
  ),
  NavDestination(
    label: 'Week',
    icon: Icons.view_week_outlined,
    activeIcon: Icons.view_week,
    placeholder: _PlaceholderScreen(label: 'Week'),
  ),
  NavDestination(
    label: 'Goals',
    icon: Icons.star_outline,
    activeIcon: Icons.star,
    placeholder: _PlaceholderScreen(label: 'Goals'),
  ),
  NavDestination(
    label: 'History',
    icon: Icons.history,
    activeIcon: Icons.history,
    placeholder: _PlaceholderScreen(label: 'History'),
  ),
];

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AppTypography.bodyFont,
          fontSize: 18,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
