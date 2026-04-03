import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import 'desktop_layout.dart';
import 'mobile_layout.dart';
import 'nav_destination.dart';

final selectedNavIndexProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedNavIndexProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < AppConstants.mobileBreakpoint;
        final body = navDestinations[selectedIndex].placeholder;

        if (isMobile) {
          return MobileLayout(
            body: body,
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) =>
                ref.read(selectedNavIndexProvider.notifier).state = i,
          );
        }

        return DesktopLayout(
          body: body,
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) =>
              ref.read(selectedNavIndexProvider.notifier).state = i,
        );
      },
    );
  }
}
