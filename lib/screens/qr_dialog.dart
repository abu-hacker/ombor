import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/utils.dart';
import '../models/product.dart';
import '../services/file_export.dart';
import '../services/label_service.dart';

Future<void> showQrDialog(BuildContext context, Product p) {
  return showDialog<void>(context: context, builder: (_) => _QrDialog(product: p));
}

class _QrDialog extends StatelessWidget {
  final Product product;
  const _QrDialog({required this.product});

  Future<void> _save(BuildContext context) async {
    try {
      final painter = QrPainter(
        data: product.qrCode,
        version: QrVersions.auto,
        gapless: true,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      );
      final bd = await painter.toImageData(800, format: ui.ImageByteFormat.png);
      if (bd == null) throw AppException("QR rasmini yaratib bo'lmadi.");
      final bytes = bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);
      final ok = await FileExport.saveBytes(fileName: 'qr_${product.qrCode}.png', bytes: bytes);
      if (ok && context.mounted) showMsg(context, 'QR saqlandi.');
    } on AppException catch (e) {
      if (context.mounted) showMsg(context, e.message, error: true);
    } catch (_) {
      if (context.mounted) showMsg(context, kGenericError, error: true);
    }
  }

  Future<void> _print(BuildContext context) async {
    try {
      final bytes = await LabelService.qrPage(product);
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: 'qr_${product.qrCode}.pdf');
    } catch (_) {
      if (context.mounted) showMsg(context, kGenericError, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBarcode = product.barcode != null && product.barcode!.isNotEmpty;
    return AlertDialog(
      title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: QrImageView(
              data: product.qrCode,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(product.qrCode, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
          if (hasBarcode) ...[
            const SizedBox(height: 12),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(6),
              child: BarcodeWidget(
                barcode: Barcode.code128(),
                data: product.barcode!,
                width: 240,
                height: 60,
                color: Colors.black,
                errorBuilder: (c, e) => Text('Barcode: ${product.barcode}', style: const TextStyle(color: Colors.black)),
              ),
            ),
          ],
        ]),
      ),
      actions: [
        TextButton.icon(onPressed: () => _save(context), icon: const Icon(Icons.download), label: const Text('Saqlash')),
        TextButton.icon(onPressed: () => _print(context), icon: const Icon(Icons.print), label: const Text('Chop etish')),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Yopish')),
      ],
    );
  }
}
