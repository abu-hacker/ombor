#!/bin/sh
set -e
flutter create --platforms=android,windows --project-name tovar_boshqaruv --org uz.tovar .
rm -f test/widget_test.dart
dart tool/patch_android.dart
flutter pub get
echo "Tayyor! Android APK: flutter build apk --release"
