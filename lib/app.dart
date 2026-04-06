import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'presentation/auth/screens/login_screen.dart';
import 'presentation/shared/layouts/app_shell.dart';
import 'providers/auth_provider.dart';
import 'providers/sync_provider.dart';

class GoaldenApp extends StatelessWidget {
  const GoaldenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goalden',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const _AuthGate(),
    );
  }
}

/// Routes to [AppShell] when authenticated, [LoginScreen] otherwise.
/// Also observes app lifecycle to trigger a push sync on resume.
class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate();

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Triggers a push sync whenever the app returns to the foreground,
  /// but only when a user is currently authenticated.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final user = ref.read(authUserProvider).valueOrNull;
      if (user != null) {
        ref.read(syncActionsProvider.notifier).pushSync();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
