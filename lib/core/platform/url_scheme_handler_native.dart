import 'dart:io';

import 'package:flutter/material.dart';

Future<void> registerLinuxUrlScheme() async {
  if (!Platform.isLinux) return;
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
    await Process.run('update-desktop-database', [appsDir.path]);
  } catch (e) {
    debugPrint('URL scheme registration failed: $e');
  }
}
