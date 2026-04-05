import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/connectivity_provider.dart';
import '../../profile/screens/profile_screen.dart';
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

          // Offline indicator
          _OfflineIndicator(ref: ref),
          // User profile + settings
          _AccountMenu(context: context, ref: ref),
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

enum _SettingsAction { profile, logout }

// ─── Offline indicator ────────────────────────────────────────────────────────

class _OfflineIndicator extends StatelessWidget {
  const _OfflineIndicator({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;
    if (isOnline) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off_outlined,
            size: 12,
            color: AppColors.textMuted,
          ),
          SizedBox(width: 5),
          Text(
            'Offline',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Account menu ─────────────────────────────────────────────────────────────

class _AccountMenu extends StatefulWidget {
  const _AccountMenu({required this.context, required this.ref});

  final BuildContext context;
  final WidgetRef ref;

  @override
  State<_AccountMenu> createState() => _AccountMenuState();
}

class _AccountMenuState extends State<_AccountMenu> {
  bool _hovered = false;

  Future<void> _openMenu() async {
    final renderBox = context.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final buttonRect = renderBox.localToGlobal(
          Offset.zero,
          ancestor: overlay,
        ) &
        renderBox.size;
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(
        buttonRect.left,
        buttonRect.top - 8,
        buttonRect.width,
        0,
      ),
      Offset.zero & overlay.size,
    );

    final user = widget.ref.read(authUserProvider).valueOrNull;
    final displayName =
        user?.displayName ?? user?.email?.split('@').firstOrNull ?? 'Account';
    final email = user?.email;

    final result = await showMenu<_SettingsAction>(
      context: context,
      position: position,
      constraints: const BoxConstraints(minWidth: 240),
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 10,
      items: [
        // User header — non-clickable
        PopupMenuItem<_SettingsAction>(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (email != null) ...[
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        // Profile
        const PopupMenuItem<_SettingsAction>(
          value: _SettingsAction.profile,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          mouseCursor: SystemMouseCursors.click,
          child: _MenuRow(
            icon: Icons.person_outline,
            label: 'Profile',
          ),
        ),
        const PopupMenuDivider(height: 1),
        // Log out
        const PopupMenuItem<_SettingsAction>(
          value: _SettingsAction.logout,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          mouseCursor: SystemMouseCursors.click,
          child: _MenuRow(
            icon: Icons.logout,
            label: 'Log out',
            color: AppColors.error,
          ),
        ),
      ],
    );

    if (!mounted) return;
    if (result == _SettingsAction.profile) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
      );
    } else if (result == _SettingsAction.logout) {
      widget.ref.read(authActionsProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.ref.watch(authUserProvider).valueOrNull;
    final displayName =
        user?.displayName ?? user?.email?.split('@').firstOrNull ?? 'Account';
    final email = user?.email;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xxl,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: _openMenu,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: _hovered
                  ? AppColors.goldenDim.withValues(alpha: 0.5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTypography.bodyFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (email != null)
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTypography.bodyFont,
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.unfold_more,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Row(
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: AppSpacing.md),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 14,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
