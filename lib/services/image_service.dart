import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../core/utils.dart';

/// Rasmlarni saqlash va avtomatik siqish (max 900px, JPEG 80%).
class ImageService {
  ImageService._();

  static Directory? _dir;

  static Future<void> init() async {
    await imagesDir();
  }

  static Future<Directory> imagesDir() async {
    final cached = _dir;
    if (cached != null) return cached;
    final base = await getApplicationSupportDirectory();
    final d = Directory(p.join(base.path, 'images'));
    await d.create(recursive: true);
    _dir = d;
    return d;
  }

  /// DBda faqat fayl nomi saqlanadi (qurilmalar orasida ko'chirish uchun).
  static File? file(String? name) {
    final d = _dir;
    if (d == null || name == null || name.isEmpty) return null;
    return File(p.join(d.path, name));
  }

  static Future<void> delete(String? name) async {
    try {
      final f = file(name);
      if (f != null && await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// Rasm tanlaydi, siqadi va saqlaydi. Fayl nomini qaytaradi (bekor qilinsa null).
  static Future<String?> pick({required bool camera}) async {
    Uint8List? bytes;
    if (isMobile) {
      final x = await ImagePicker().pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (x == null) return null;
      bytes = await x.readAsBytes();
    } else {
      final r = await FilePicker.platform
          .pickFiles(type: FileType.image, withData: true);
      if (r == null || r.files.isEmpty) return null;
      final f = r.files.single;
      bytes = f.bytes ?? (f.path != null ? await File(f.path!).readAsBytes() : null);
    }
    if (bytes == null) return null;
    final out = await compute(_compressImage, bytes);
    if (out == null) throw AppException("Rasm formatini o'qib bo'lmadi.");
    final dir = await imagesDir();
    final name =
        'img_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}.jpg';
    await File(p.join(dir.path, name)).writeAsBytes(out, flush: true);
    return name;
  }
}

Uint8List? _compressImage(Uint8List bytes) {
  try {
    var im = img.decodeImage(bytes);
    if (im == null) return null;
    im = img.bakeOrientation(im);
    const maxSide = 900;
    if (im.width > maxSide || im.height > maxSide) {
      im = im.width >= im.height
          ? img.copyResize(im, width: maxSide)
          : img.copyResize(im, height: maxSide);
    }
    return Uint8List.fromList(img.encodeJpg(im, quality: 80));
  } catch (_) {
    return null;
  }
}
