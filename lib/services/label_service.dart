import 'dart:typed_data';
import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../core/utils.dart';
import '../models/product.dart';
import 'image_service.dart';

/// Narx yorlig'i va QR sahifasini PDF sifatida yaratadi.
class LabelService {
  LabelService._();

  static Future<pw.Font?> _font(String path) async {
    try {
      final d = await rootBundle.load(path);
      return pw.Font.ttf(d);
    } catch (_) {
      return null;
    }
  }

  static Future<pw.Document> _doc() async {
    final regular = await _font('assets/fonts/NotoSans-Regular.ttf');
    final bold = await _font('assets/fonts/NotoSans-Bold.ttf');
    if (regular == null) return pw.Document();
    return pw.Document(
        theme: pw.ThemeData.withFont(base: regular, bold: bold ?? regular));
  }

  static bool _ascii(String s) => RegExp(r'^[\x20-\x7E]+$').hasMatch(s);

  static Future<Uint8List> build(Product p, int copies) async {
    final doc = await _doc();
    pw.MemoryImage? image;
    final f = ImageService.file(p.imagePath);
    if (f != null && await f.exists()) {
      image = pw.MemoryImage(await f.readAsBytes());
    }
    final n = copies.clamp(1, 1000);
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (ctx) => [
        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(n, (_) => _label(p, image)),
        ),
      ],
    ));
    return doc.save();
  }

  static pw.Widget _label(Product p, pw.MemoryImage? image) {
    final hasBarcode = p.barcode != null && p.barcode!.isNotEmpty && _ascii(p.barcode!);
    return pw.Container(
      width: 9 * PdfPageFormat.cm,
      height: 5 * PdfPageFormat.cm,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.8),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (image != null)
            pw.Container(
              width: 52,
              height: 52,
              margin: const pw.EdgeInsets.only(right: 8),
              child: pw.Image(image, fit: pw.BoxFit.cover),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(p.name,
                    maxLines: 2,
                    style: pw.TextStyle(
                        fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Chakana: ${formatMoney(p.retailPrice)}',
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Ulgurji: ${formatMoney(p.wholesalePrice)}',
                        style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
                if (hasBarcode)
                  pw.BarcodeWidget(
                    barcode: bw.Barcode.code128(),
                    data: p.barcode!,
                    width: 110,
                    height: 26,
                    drawText: true,
                    textStyle: const pw.TextStyle(fontSize: 7),
                  )
                else
                  pw.Text(p.productCode, style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.BarcodeWidget(
                barcode: bw.Barcode.qrCode(),
                data: p.qrCode,
                width: 64,
                height: 64,
              ),
              pw.SizedBox(height: 2),
              pw.Text(p.qrCode, style: const pw.TextStyle(fontSize: 6)),
            ],
          ),
        ],
      ),
    );
  }

  /// Faqat QR kodli sahifa (chop etish uchun).
  static Future<Uint8List> qrPage(Product p) async {
    final doc = await _doc();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a6,
      build: (ctx) => pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(p.name,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.BarcodeWidget(
              barcode: bw.Barcode.qrCode(),
              data: p.qrCode,
              width: 180,
              height: 180,
            ),
            pw.SizedBox(height: 8),
            pw.Text(p.qrCode, style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
      ),
    ));
    return doc.save();
  }
}
