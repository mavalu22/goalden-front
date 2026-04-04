import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';
import 'nav_destination.dart';

class MobileLayout extends StatelessWidget {
  const MobileLayout({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final Widget body;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _MobileAppBar(),
      body: body,
      bottomNavigationBar: _BottomTabBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
      ),
    );
  }
}

class _MobileAppBar extends ConsumerWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textSecondary, size: 22),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const Spacer(),
          const Text(
            'GOALDEN',
            style: TextStyle(
              fontFamily: AppTypography.displayFont,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.golden,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          PopupMenuButton<_SettingsAction>(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary, size: 22),
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            onSelected: (action) {
              if (action == _SettingsAction.logout) {
                ref.read(authActionsProvider.notifier).signOut();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _SettingsAction.logout,
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 16, color: AppColors.textSecondary),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      'Log out',
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _SettingsAction { logout }

class _BottomTabBar extends StatelessWidget {
  const _BottomTabBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(navDestinations.length, (i) {
              final dest = navDestinations[i];
              final isActive = i == selectedIndex;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                  onTap: () => onDestinationSelected(i),
                  mouseCursor: SystemMouseCursors.click,
                  hoverColor: AppColors.golden.withValues(alpha: 0.06),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? dest.activeIcon : dest.icon,
                        size: 22,
                        color: isActive ? AppColors.golden : AppColors.textMuted,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        dest.label.toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppTypography.bodyFont,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: isActive ? AppColors.golden : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
