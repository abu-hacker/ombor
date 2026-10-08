# Tovar boshqaruv (Flutter · Android + Windows · offline)

## 1. O'rnatish (bir marta)
Kerak: Flutter SDK (3.24+). Windows uchun Visual Studio ("Desktop development with C++"),
Android uchun Android Studio / SDK.

Loyiha papkasida:

    Windows:  setup.bat
    Linux/Mac: ./setup.sh

Skript `flutter create` bilan android/windows papkalarini yaratadi, kamera ruxsatini
qo'shadi va `flutter pub get` ni ishga tushiradi.

## 2. Ishga tushirish va qurish
    flutter run -d windows
    flutter run                      (Android telefon ulangan bo'lsa)
    flutter build apk --release      -> build/app/outputs/flutter-apk/app-release.apk
    flutter build windows --release  -> build/windows/x64/runner/Release/

## 3. Tuzilma
    lib/core          yordamchi funksiyalar, navigatsiya, sozlamalar
    lib/database      SQLite sxema + migratsiyalar (kelajak versiyalar uchun)
    lib/models        Product, Category, StockMovement ...
    lib/repositories  barcha DB amallari (tranzaksiyalar bilan)
    lib/services      rasm siqish, backup, PDF yorliq, fayl eksport
    lib/screens       ekranlar
    lib/widgets       qayta ishlatiladigan vidjetlar
    lib/theme         Light/Dark mavzu

## 4. Eslatmalar
- Windows'da kamera orqali skanerlash yo'q: kodni qo'lda yoki USB barcode skaner
  (klaviatura sifatida ishlaydi) bilan kiritiladi.
- Windows'da "sqlite3.dll topilmadi" xatosi chiqsa, sqlite3.dll ni .exe yoniga qo'ying.
- PDF yorliqda kirill/maxsus harflar uchun assets/fonts/ ga NotoSans-Regular.ttf va
  NotoSans-Bold.ttf qo'ying (ixtiyoriy).
- Backup: Android'da ulashish oynasi (Drive/Telegram/Fayllar), Windows'da "Saqlash" oynasi.
  Yangi qurilmada: Sozlamalar -> Backup tiklash.
