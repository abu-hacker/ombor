import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/utils.dart';

class FileExport {
  FileExport._();

  /// Android: ulashish oynasi (Drive, Telegram, Fayllar...). Windows: "Saqlash" oynasi.
  /// Saqlangan/ulashilgan bo'lsa true.
  static Future<bool> saveBytes({
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (isMobile) {
      final dir = await getTemporaryDirectory();
      final f = File(p.join(dir.path, fileName));
      await f.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([XFile(f.path)]);
      return true;
    }
    final path = await FilePicker.platform
        .saveFile(dialogTitle: 'Saqlash', fileName: fileName);
    if (path == null) return false;
    await File(path).writeAsBytes(bytes, flush: true);
    return true;
  }
}
