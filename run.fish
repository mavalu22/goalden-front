#!/usr/bin/env fish
# Usage: fish run.fish [run|build|build-android|build-android-release|analyze|gen]

set FLUTTER /home/bigo/flutter/bin/flutter
set ENV_FILE .env

switch $argv[1]
    case build
        $FLUTTER build linux --dart-define-from-file=$ENV_FILE
    case build-android
        $FLUTTER build apk --dart-define-from-file=$ENV_FILE
    case build-android-release
        $FLUTTER build apk --release --dart-define-from-file=$ENV_FILE
    case analyze
        $FLUTTER analyze
    case gen
        $FLUTTER pub run build_runner build --delete-conflicting-outputs
    case '*'
        $FLUTTER run -d linux --dart-define-from-file=$ENV_FILE
end
