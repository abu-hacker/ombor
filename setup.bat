@echo off
echo [1/4] Platforma fayllari yaratilmoqda...
call flutter create --platforms=android,windows --project-name tovar_boshqaruv --org uz.tovar .
if exist test\widget_test.dart del test\widget_test.dart
echo [2/4] Android ruxsatlari...
call dart tool\patch_android.dart
echo [3/4] Paketlar yuklanmoqda...
call flutter pub get
echo [4/4] Tayyor!
echo.
echo Ishga tushirish:  flutter run -d windows
echo Android APK:      flutter build apk --release
echo Windows EXE:      flutter build windows --release
