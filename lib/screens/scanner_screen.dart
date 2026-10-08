import 'package:flutter/material.dart';
import '../core/utils.dart';
import '../repositories/product_repository.dart';
import '../widgets/common.dart';
import '../widgets/scanner_view.dart';
import 'product_form_screen.dart';
import 'quick_product_sheet.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _manual = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  Future<void> _handle(String code) async {
    if (_busy) return;
    _busy = true;
    try {
      final p = await ProductRepository.I.findByCode(code);
      if (!mounted) return;
      if (p != null) {
        await showQuickProductSheet(context, p.id!);
      } else {
        await _notFound(code);
      }
    } catch (_) {
      if (mounted) showMsg(context, kGenericError, error: true);
    } finally {
      await Future.delayed(const Duration(milliseconds: 1200));
      _busy = false;
    }
  }

  Future<void> _notFound(String code) async {
    final add = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mahsulot topilmadi'),
        content: Text('"$code" kodi bo\'yicha tovar yo\'q.\nUni yangi tovar sifatida qo\'shasizmi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Yo\'q')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Tovar qo'shish")),
        ],
      ),
    );
    if (add == true && mounted) {
      await Navigator.push<bool>(
          context, MaterialPageRoute(builder: (_) => ProductFormScreen(initialBarcode: code)));
    }
  }

  void _submitManual() {
    final v = _manual.text.trim();
    if (v.isEmpty) {
      showMsg(context, 'Kodni kiriting.', error: true);
      return;
    }
    _manual.clear();
    _handle(v);
  }

  Widget _manualField() => Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: _manual,
          autofocus: !isMobile,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _submitManual(),
          decoration: inputDec(isMobile ? "Yoki kodni qo'lda kiriting" : 'Kodni kiriting yoki USB skanerdan o\'qing',
              suffix: IconButton(icon: const Icon(Icons.search), onPressed: _submitManual)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skaner')),
      body: isMobile
          ? Column(children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ScannerView(onCode: _handle),
                  ),
                ),
              ),
              _manualField(),
            ])
          : Constrained(
              maxWidth: 560,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.qr_code_scanner, size: 72),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "Windows'da QR/Barcode kodini kiriting yoki USB barcode skaneridan o'qing — mahsulot darhol topiladi.",
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                _manualField(),
              ]),
            ),
    );
  }
}
