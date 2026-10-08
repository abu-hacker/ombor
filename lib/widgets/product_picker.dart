import 'package:flutter/material.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';
import 'common.dart';

/// Kirim/chiqim uchun mahsulot tanlash oynasi (qidiruv bilan).
Future<Product?> pickProduct(BuildContext context) {
  return showDialog<Product>(context: context, builder: (_) => const _PickerDialog());
}

class _PickerDialog extends StatefulWidget {
  const _PickerDialog();
  @override
  State<_PickerDialog> createState() => _PickerDialogState();
}

class _PickerDialogState extends State<_PickerDialog> {
  final _c = TextEditingController();
  List<Product> _items = [];
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    final my = ++_seq;
    try {
      final r = await ProductRepository.I.list(query: q, sort: SortKey.name, ascending: true, limit: 50);
      if (mounted && my == _seq) setState(() => _items = r);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tovarni tanlang'),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(children: [
          TextField(
            controller: _c,
            autofocus: true,
            onChanged: _search,
            decoration: inputDec('Qidirish (nom, kod, QR, barcode)').copyWith(prefixIcon: const Icon(Icons.search)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('Tovar topilmadi'))
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final p = _items[i];
                      return ListTile(
                        leading: ProductImage(path: p.imagePath, size: 40, radius: 8),
                        title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('Qoldiq: ${p.quantity}'),
                        onTap: () => Navigator.pop(context, p),
                      );
                    },
                  ),
          ),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish'))],
    );
  }
}
