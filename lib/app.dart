import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'presentation/auth/screens/login_screen.dart';
import 'presentation/shared/layouts/app_shell.dart';
import 'providers/auth_provider.dart';
import 'providers/sync_provider.dart';

class GoaldenApp extends ConsumerWidget {
  const GoaldenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Goalden',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const _AuthGate(),
    );
  }
}

/// Routes to [AppShell] when authenticated, [LoginScreen] otherwise.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authUserProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // Kick off the initial cloud pull in the background.
          // Errors are surfaced via syncStatusProvider, not as exceptions.
          ref.watch(initialSyncProvider);
        }
        return user != null ? const AppShell() : const LoginScreen();
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.golden),
        ),
      ),
      error: (_, __) => const LoginScreen(),
    );
  }
}
