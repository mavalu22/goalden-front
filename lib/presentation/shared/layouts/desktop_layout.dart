import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';
import 'nav_destination.dart';

class DesktopLayout extends StatelessWidget {
  const DesktopLayout({
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
      body: Row(
        children: [
          _Sidebar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
          ),
          const VerticalDivider(width: 1, color: AppColors.border),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: AppConstants.sidebarWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xxl,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            child: Text(
              'GOALDEN',
              style: TextStyle(
                fontFamily: AppTypography.displayFont,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.golden,
                letterSpacing: 2,
              ),
            ),
          ),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              itemCount: navDestinations.length,
              itemBuilder: (context, i) {
                final dest = navDestinations[i];
                final isActive = i == selectedIndex;

                return _SidebarNavItem(
                  label: dest.label,
                  icon: isActive ? dest.activeIcon : dest.icon,
                  isActive: isActive,
                  onTap: () => onDestinationSelected(i),
                );
              },
            ),
          ),

          // New Goal button
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.golden,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'New Goal',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // User profile + settings
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.surface,
                  child: Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Account',
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                PopupMenuButton<_SettingsAction>(
                  icon: const Icon(
                    Icons.settings_outlined,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  padding: EdgeInsets.zero,
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
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          hoverColor: AppColors.goldenDim.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: isActive ? AppColors.goldenDim : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? AppColors.golden : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? AppColors.golden : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _SettingsAction { logout }
