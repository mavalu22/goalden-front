import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  // On Linux, register the custom URL scheme so OAuth callbacks reach the app.
  if (Platform.isLinux) {
    await _registerLinuxUrlScheme();
  }

  // Handle OAuth callbacks delivered as deep links.
  final appLinks = AppLinks();

  // Check if this instance was launched by an OAuth callback URI (fallback for
  // platforms where single-instance routing isn't fully operational).
  // Wrapped in try-catch because getInitialLink() may return a stale URI from
  // a previous session whose flow state has already expired in Supabase.
  final initialUri = await appLinks.getInitialLink();
  if (initialUri != null) {
    try {
      await Supabase.instance.client.auth.getSessionFromUrl(initialUri);
    } catch (_) {
      // Stale or already-consumed flow state — safe to ignore.
    }
  }

  // Stream for subsequent deep links while the app is already running
  // (primary instance receives the URI forwarded from the secondary via D-Bus).
  appLinks.uriLinkStream.listen((uri) {
    Supabase.instance.client.auth.getSessionFromUrl(uri);
  });

  runApp(
    const ProviderScope(
      child: GoaldenApp(),
    ),
  );
}

/// Creates a `.desktop` file and registers `io.supabase.goalden://` with the
/// XDG MIME system so the OS routes OAuth callbacks back to the app.
Future<void> _registerLinuxUrlScheme() async {
  try {
    final execPath = Platform.resolvedExecutable;
    final home = Platform.environment['HOME'] ?? '';
    final appsDir = Directory('$home/.local/share/applications');
    await appsDir.create(recursive: true);

    final desktopFile = File('${appsDir.path}/goalden.desktop');
    await desktopFile.writeAsString(
      '[Desktop Entry]\n'
      'Name=Goalden\n'
      'Exec=$execPath %u\n'
      'Type=Application\n'
      'MimeType=x-scheme-handler/io.supabase.goalden;\n'
      'NoDisplay=true\n',
    );

    await Process.run('xdg-mime', [
      'default',
      'goalden.desktop',
      'x-scheme-handler/io.supabase.goalden',
    ]);
    await Process.run(
      'update-desktop-database',
      [appsDir.path],
    );
  } catch (e) {
    // Non-fatal — app works, but Google OAuth deep link may not return.
    debugPrint('URL scheme registration failed: $e');
  }
}
