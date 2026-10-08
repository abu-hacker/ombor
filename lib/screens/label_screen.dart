import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../core/utils.dart';
import '../models/product.dart';
import '../services/label_service.dart';
import '../widgets/common.dart';

/// Narx yorlig'i: nechta dona kerakligini tanlab, chop etish yoki PDF saqlash.
class LabelScreen extends StatefulWidget {
  final Product product;
  const LabelScreen({super.key, required this.product});
  @override
  State<LabelScreen> createState() => _LabelScreenState();
}

class _LabelScreenState extends State<LabelScreen> {
  int _copies = 1;

  void _set(int v) => setState(() => _copies = v.clamp(1, 500));

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      appBar: AppBar(title: const Text("Narx yorlig'i")),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(children: [
            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton.filledTonal(onPressed: () => _set(_copies - 1), icon: const Icon(Icons.remove)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$_copies dona', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              IconButton.filledTonal(onPressed: () => _set(_copies + 1), icon: const Icon(Icons.add)),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              for (final n in [1, 6, 10, 24, 50])
                ChoiceChip(label: Text('$n'), selected: _copies == n, onSelected: (_) => _set(n)),
            ]),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: PdfPreview(
            key: ValueKey(_copies),
            build: (format) => LabelService.build(p, _copies),
            initialPageFormat: PdfPageFormat.a4,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            allowPrinting: true,
            allowSharing: true,
            pdfFileName: 'yorliq_${p.productCode}.pdf',
            onError: (context, error) => const EmptyState(icon: Icons.error_outline, text: kGenericError),
          ),
        ),
      ]),
    );
  }
}
