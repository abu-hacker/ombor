import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Kamera orqali QR/Barcode o'qish (Android). Ruxsat berilmasa tushunarli xabar chiqadi.
class ScannerView extends StatefulWidget {
  final void Function(String code) onCode;
  const ScannerView({super.key, required this.onCode});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  final MobileScannerController _c = MobileScannerController();
  bool _torch = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    for (final b in capture.barcodes) {
      final v = b.rawValue;
      if (v != null && v.isNotEmpty) {
        widget.onCode(v);
        return;
      }
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _c.toggleTorch();
      if (mounted) setState(() => _torch = !_torch);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _c,
          onDetect: _onDetect,
          errorBuilder: (context, error, child) {
            final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
            return Container(
              color: Colors.black,
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 56),
                const SizedBox(height: 12),
                Text(
                  denied
                      ? 'Kameradan foydalanish uchun ruxsat bering.'
                      : "Kamerani ishga tushirib bo'lmadi.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await _c.start();
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Qayta urinish'),
                ),
              ]),
            );
          },
        ),
        IgnorePointer(
          child: Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: IconButton.filled(
            onPressed: _toggleTorch,
            icon: Icon(_torch ? Icons.flash_on : Icons.flash_off),
          ),
        ),
      ],
    );
  }
}

/// Bir marta skanerlab kodni qaytaradi (masalan, barcode maydonini to'ldirish uchun).
class ScanOncePage extends StatefulWidget {
  const ScanOncePage({super.key});
  @override
  State<ScanOncePage> createState() => _ScanOncePageState();
}

class _ScanOncePageState extends State<ScanOncePage> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kodni skanerlang')),
      body: ScannerView(onCode: (code) {
        if (_done) return;
        _done = true;
        Navigator.pop(context, code);
      }),
    );
  }
}
