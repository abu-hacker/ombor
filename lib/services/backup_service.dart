import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../core/data_bus.dart';
import '../core/utils.dart';
import '../database/app_database.dart';
import '../models/records.dart';
import 'image_service.dart';

/// Backup = ZIP: data.json (barcha jadvallar) + images/ (barcha rasmlar).
class BackupService {
  BackupService._();

  static const String _appId = 'tovar_boshqaruv';
  static const int _format = 1;
  static const String _bad =
      "Backup fayli buzilgan yoki noto'g'ri. Tiklash to'xtatildi, ma'lumotlaringiz o'zgarmadi.";

  static const List<String> _tables = [
    'categories',
    'products',
    'stock_movements',
    'price_history',
    'product_history',
    'settings',
  ];

  static String suggestedFileName() {
    final d = DateTime.now();
    String t(int n) => n.toString().padLeft(2, '0');
    return 'tovar_backup_${d.year}${t(d.month)}${t(d.day)}_${t(d.hour)}${t(d.minute)}.zip';
  }

  static Future<Uint8List> create() async {
    final db = await AppDatabase.instance;
    final tables = <String, Object?>{};
    for (final t in _tables) {
      tables[t] = await db.query(t);
    }
    final data = {
      'app': _appId,
      'format': _format,
      'created_at': nowIso(),
      'tables': tables,
    };
    final jsonBytes = utf8.encode(jsonEncode(data));
    final archive = Archive();
    archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));

    final products = tables['products'] as List;
    final added = <String>{};
    for (final row in products) {
      final name = (row as Map)['image_path'] as String?;
      if (name == null || name.isEmpty || !added.add(name)) continue;
      final f = ImageService.file(name);
      if (f != null && await f.exists()) {
        final b = await f.readAsBytes();
        archive.addFile(ArchiveFile('images/$name', b.length, b));
      }
    }
    final out = ZipEncoder().encode(archive);
    if (out == null) throw AppException("Backup yaratib bo'lmadi.");
    return Uint8List.fromList(out);
  }

  static Future<void> record(String fileName, int size) async {
    final db = await AppDatabase.instance;
    await db.insert('backups',
        {'file_name': fileName, 'size': size, 'created_at': nowIso()});
    // faqat oxirgi 20 tasi saqlansin
    await db.execute(
        'DELETE FROM backups WHERE id NOT IN (SELECT id FROM backups ORDER BY id DESC LIMIT 20)');
  }

  static Future<List<BackupRecord>> recent() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('backups', orderBy: 'id DESC', limit: 5);
    return rows
        .map((r) => BackupRecord(r['file_name'] as String,
            (r['size'] as num).toInt(), r['created_at'] as String))
        .toList();
  }

  static Future<void> restore(Uint8List bytes) async {
    Archive archive;
    Map<String, dynamic> data;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
      final f = archive.findFile('data.json');
      if (f == null) throw AppException(_bad);
      data = jsonDecode(utf8.decode(List<int>.from(f.content as List)))
          as Map<String, dynamic>;
    } catch (_) {
      throw AppException(_bad);
    }
    if (data['app'] != _appId || data['tables'] is! Map) {
      throw AppException(_bad);
    }
    final tables = Map<String, dynamic>.from(data['tables'] as Map);
    for (final t in _tables) {
      if (tables[t] is! List) throw AppException(_bad);
    }

    final db = await AppDatabase.instance;
    try {
      await db.transaction((txn) async {
        for (final t in [
          'stock_movements',
          'price_history',
          'product_history',
          'products',
          'categories',
          'settings',
        ]) {
          await txn.delete(t);
        }
        for (final t in _tables) {
          final batch = txn.batch();
          for (final row in tables[t] as List) {
            batch.insert(t, Map<String, Object?>.from(row as Map));
          }
          await batch.commit(noResult: true);
        }
      });
    } catch (_) {
      throw AppException(_bad);
    }

    // Rasmlarni tiklash (baza muvaffaqiyatli almashtirilgandan keyin)
    final dir = await ImageService.imagesDir();
    final keep = <String>{};
    for (final f in archive.files) {
      if (!f.isFile || !f.name.startsWith('images/')) continue;
      final name = p.basename(f.name);
      if (name.isEmpty) continue;
      await File(p.join(dir.path, name))
          .writeAsBytes(List<int>.from(f.content as List), flush: true);
      keep.add(name);
    }
    try {
      await for (final e in dir.list()) {
        if (e is File && !keep.contains(p.basename(e.path))) {
          await e.delete();
        }
      }
    } catch (_) {}
    DataBus.I.changed();
  }
}
