import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'presentation/auth/screens/login_screen.dart';

class GoaldenApp extends ConsumerWidget {
  const GoaldenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Goalden',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      // Auth routing will be wired in TASK-009.
      // For now the app opens directly on the login screen.
      home: const LoginScreen(),
    );
  }
}
