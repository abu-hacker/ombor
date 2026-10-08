import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/app_settings.dart';
import 'database/app_database.dart';
import 'screens/home_shell.dart';
import 'services/image_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    try {
      await ImageService.init();
      await AppDatabase.instance;
      await AppSettings.I.load();
    } catch (e) {
      runApp(_ErrorApp(message: '$e'));
      return;
    }
    runApp(const TovarApp());
  }, (error, stack) {
    debugPrint('Kutilmagan xatolik: $error');
  });
}

class TovarApp extends StatelessWidget {
  const TovarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.I,
      builder: (context, _) => MaterialApp(
        title: 'Tovar boshqaruv',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: AppSettings.I.themeMode,
        home: const HomeShell(),
      ),
    );
  }
}

class _ErrorApp extends StatelessWidget {
  final String message;
  const _ErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "Ilovani ishga tushirib bo'lmadi.\n\n$message",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
