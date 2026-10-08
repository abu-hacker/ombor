import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';

class SettingsRepository {
  SettingsRepository._();
  static final SettingsRepository I = SettingsRepository._();

  Future<String?> get(String key) async {
    final db = await AppDatabase.instance;
    final r = await db.query('settings',
        where: 'key = ?', whereArgs: [key], limit: 1);
    if (r.isEmpty) return null;
    return r.first['value'] as String?;
  }

  Future<void> set(String key, String value) async {
    final db = await AppDatabase.instance;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
