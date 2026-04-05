import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/auth_user.dart';
import '../../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  bool _nameSaving = false;
  bool _resetSent = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authUserProvider).valueOrNull;
    _nameController = TextEditingController(text: user?.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    setState(() => _nameSaving = true);
    try {
      await ref.read(authActionsProvider.notifier).updateDisplayName(newName);
    } finally {
      if (mounted) setState(() => _nameSaving = false);
    }
  }

  Future<void> _sendPasswordReset(String? email) async {
    if (email == null) return;
    setState(() => _resetSent = true);
    await ref
        .read(authActionsProvider.notifier)
        .sendPasswordResetEmail(email);
  }

  @override
  Widget build(BuildContext context) {
    // Pop to root when the user signs out so _AuthGate shows LoginScreen.
    ref.listen<AsyncValue<AppUser?>>(authUserProvider, (_, next) {
      next.whenOrNull(
        data: (user) {
          if (user == null && mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
      );
    });

    final user = ref.watch(authUserProvider).valueOrNull;
    final isEmailUser = user?.authProvider == AuthProvider.email;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Display name ──────────────────────────────────────────────
                const _SectionLabel(label: 'Display Name'),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _ProfileTextField(
                        controller: _nameController,
                        hint: 'Your name',
                        onSubmitted: (_) => _saveName(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _SaveButton(
                      loading: _nameSaving,
                      onTap: _saveName,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Email ────────────────────���────────────────────────────────
                const _SectionLabel(label: 'Email'),
                const SizedBox(height: AppSpacing.sm),
                _ReadOnlyField(value: user?.email ?? '—'),

                // ── Password (email users only) ───────────────────────────────
                if (isEmailUser) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionLabel(label: 'Password'),
                  const SizedBox(height: AppSpacing.sm),
                  const _ReadOnlyField(value: '••••••••'),
                  const SizedBox(height: AppSpacing.sm),
                  _resetSent
                      ? const Text(
                          'Password reset email sent. Check your inbox.',
                          style: TextStyle(
                            fontFamily: AppTypography.bodyFont,
                            fontSize: 13,
                            color: AppColors.golden,
                          ),
                        )
                      : GestureDetector(
                          onTap: () => _sendPasswordReset(user?.email),
                          child: const Text(
                            'Change password',
                            style: TextStyle(
                              fontFamily: AppTypography.bodyFont,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.golden,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.golden,
                            ),
                          ),
                        ),
                ],

                const SizedBox(height: AppSpacing.xxxl),

                // ── Log out ───────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: _LogoutButton(
                    onTap: () =>
                        ref.read(authActionsProvider.notifier).signOut(),
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

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontFamily: AppTypography.bodyFont,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.hint,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Center(
        child: TextField(
          controller: controller,
          onSubmitted: onSubmitted,
          style: const TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 14,
              color: AppColors.textMuted,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: const TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.onTap, required this.loading});

  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.golden,
          foregroundColor: AppColors.background,
          disabledBackgroundColor: AppColors.golden.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
        child: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.background,
                ),
              )
            : const Text(
                'Save',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      ),
      icon: const Icon(Icons.logout, size: 16),
      label: const Text(
        'Log out',
        style: TextStyle(
          fontFamily: AppTypography.bodyFont,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
