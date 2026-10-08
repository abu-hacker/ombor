import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/utils.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';
import '../widgets/common.dart';

const List<String> kOutReasons = ['Buzilgan', "Yo'qolgan", 'Qaytarilgan', 'Boshqa sabab'];

Future<bool> showStockInDialog(BuildContext context, Product p) async =>
    (await showDialog<bool>(context: context, builder: (_) => _StockInDialog(product: p))) ?? false;

Future<bool> showStockOutDialog(BuildContext context, Product p) async =>
    (await showDialog<bool>(context: context, builder: (_) => _StockOutDialog(product: p))) ?? false;

Future<bool> showAdjustDialog(BuildContext context, Product p) async =>
    (await showDialog<bool>(context: context, builder: (_) => _AdjustDialog(product: p))) ?? false;

Future<bool> showPriceDialog(BuildContext context, Product p) async =>
    (await showDialog<bool>(context: context, builder: (_) => _PriceDialog(product: p))) ?? false;

final _digits = [FilteringTextInputFormatter.digitsOnly];

class _DialogBody extends StatelessWidget {
  final List<Widget> children;
  final String? error;
  const _DialogBody({required this.children, this.error});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 380,
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final c in children) Padding(padding: const EdgeInsets.only(bottom: 12), child: c),
          if (error != null)
            Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------------- KIRIM
class _StockInDialog extends StatefulWidget {
  final Product product;
  const _StockInDialog({required this.product});
  @override
  State<_StockInDialog> createState() => _StockInDialogState();
}

class _StockInDialogState extends State<_StockInDialog> {
  final _qty = TextEditingController();
  late final TextEditingController _price =
      TextEditingController(text: widget.product.purchasePrice.toString());
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _qty.dispose();
    _price.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final q = parseNonNegative(_qty.text);
    final pr = parseNonNegative(_price.text);
    if (q == null || q <= 0) {
      setState(() => _error = 'Miqdorni tekshiring.');
      return;
    }
    if (pr == null) {
      setState(() => _error = 'Narxni tekshiring.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ProductRepository.I.stockIn(
          productId: widget.product.id!, quantity: q, purchasePrice: pr, date: _date, note: _note.text);
      if (mounted) Navigator.pop(context, true);
    } on AppException catch (e) {
      if (mounted) setState(() { _error = e.message; _busy = false; });
    } catch (_) {
      if (mounted) setState(() { _error = kGenericError; _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final q = parseNonNegative(_qty.text) ?? 0;
    return AlertDialog(
      title: const Text('Tovar kirimi'),
      content: _DialogBody(error: _error, children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('${p.name}\nHozirgi qoldiq: ${p.quantity}  →  ${p.quantity + q}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        TextField(
          controller: _qty,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: _digits,
          onChanged: (_) => setState(() {}),
          decoration: inputDec('Miqdor'),
        ),
        TextField(
          controller: _price,
          keyboardType: TextInputType.number,
          inputFormatters: _digits,
          decoration: inputDec('Kelish narxi', prefixText: "so'm  "),
        ),
        DateField(date: _date, onChanged: (d) => setState(() => _date = d)),
        TextField(controller: _note, decoration: inputDec('Izoh (ixtiyoriy)')),
      ]),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Bekor qilish')),
        FilledButton(onPressed: _busy ? null : _save, child: const Text('Saqlash')),
      ],
    );
  }
}

// ------------------------------------------------------------------ CHIQIM
class _StockOutDialog extends StatefulWidget {
  final Product product;
  const _StockOutDialog({required this.product});
  @override
  State<_StockOutDialog> createState() => _StockOutDialogState();
}

class _StockOutDialogState extends State<_StockOutDialog> {
  final _qty = TextEditingController();
  final _note = TextEditingController();
  String _reason = kOutReasons.first;
  DateTime _date = DateTime.now();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final q = parseNonNegative(_qty.text);
    if (q == null || q <= 0) {
      setState(() => _error = 'Miqdorni tekshiring.');
      return;
    }
    if (q > widget.product.quantity) {
      setState(() => _error = "Yetarli qoldiq yo'q. Hozirgi qoldiq: ${widget.product.quantity}");
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ProductRepository.I.stockOut(
          productId: widget.product.id!, quantity: q, reason: _reason, date: _date, note: _note.text);
      if (mounted) Navigator.pop(context, true);
    } on AppException catch (e) {
      if (mounted) setState(() { _error = e.message; _busy = false; });
    } catch (_) {
      if (mounted) setState(() { _error = kGenericError; _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final q = parseNonNegative(_qty.text) ?? 0;
    final over = q > p.quantity;
    return AlertDialog(
      title: const Text('Tovar chiqimi'),
      content: _DialogBody(error: _error, children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('${p.name}\nHozirgi qoldiq: ${p.quantity}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        TextField(
          controller: _qty,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: _digits,
          onChanged: (_) => setState(() {}),
          decoration: inputDec('Miqdor').copyWith(
            errorText: over ? "Yetarli qoldiq yo'q (qoldiq: ${p.quantity})" : null,
          ),
        ),
        DropdownButtonFormField<String>(
          value: _reason,
          decoration: inputDec('Sabab'),
          items: [for (final r in kOutReasons) DropdownMenuItem(value: r, child: Text(r))],
          onChanged: (v) => setState(() => _reason = v ?? _reason),
        ),
        DateField(date: _date, onChanged: (d) => setState(() => _date = d)),
        TextField(controller: _note, decoration: inputDec('Izoh (ixtiyoriy)')),
      ]),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Bekor qilish')),
        FilledButton(onPressed: _busy ? null : _save, child: const Text('Saqlash')),
      ],
    );
  }
}

// ----------------------------------------------------------------- TUZATISH
class _AdjustDialog extends StatefulWidget {
  final Product product;
  const _AdjustDialog({required this.product});
  @override
  State<_AdjustDialog> createState() => _AdjustDialogState();
}

class _AdjustDialogState extends State<_AdjustDialog> {
  late final TextEditingController _qty =
      TextEditingController(text: widget.product.quantity.toString());
  final _note = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final q = parseNonNegative(_qty.text);
    if (q == null) {
      setState(() => _error = "Qoldiqni tekshiring (manfiy bo'lmasin).");
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ProductRepository.I.adjustStock(productId: widget.product.id!, newQuantity: q, note: _note.text);
      if (mounted) Navigator.pop(context, true);
    } on AppException catch (e) {
      if (mounted) setState(() { _error = e.message; _busy = false; });
    } catch (_) {
      if (mounted) setState(() { _error = kGenericError; _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Qoldiqni o'zgartirish"),
      content: _DialogBody(error: _error, children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(widget.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        TextField(
          controller: _qty,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: _digits,
          decoration: inputDec('Yangi qoldiq'),
        ),
        TextField(controller: _note, decoration: inputDec('Izoh (ixtiyoriy)')),
      ]),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Bekor qilish')),
        FilledButton(onPressed: _busy ? null : _save, child: const Text('Saqlash')),
      ],
    );
  }
}

// -------------------------------------------------------------------- NARX
class _PriceDialog extends StatefulWidget {
  final Product product;
  const _PriceDialog({required this.product});
  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  late final TextEditingController _buy =
      TextEditingController(text: widget.product.purchasePrice.toString());
  late final TextEditingController _retail =
      TextEditingController(text: widget.product.retailPrice.toString());
  late final TextEditingController _whole =
      TextEditingController(text: widget.product.wholesalePrice.toString());
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _buy.dispose();
    _retail.dispose();
    _whole.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final b = parseNonNegative(_buy.text);
    final r = parseNonNegative(_retail.text);
    final w = parseNonNegative(_whole.text);
    if (b == null || r == null || w == null) {
      setState(() => _error = 'Narxni tekshiring.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final fresh = await ProductRepository.I.findById(widget.product.id!);
      if (fresh == null) throw AppException('Mahsulot topilmadi.');
      await ProductRepository.I
          .update(fresh.copyWith(purchasePrice: b, retailPrice: r, wholesalePrice: w));
      if (mounted) Navigator.pop(context, true);
    } on AppException catch (e) {
      if (mounted) setState(() { _error = e.message; _busy = false; });
    } catch (_) {
      if (mounted) setState(() { _error = kGenericError; _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = parseNonNegative(_buy.text);
    final r = parseNonNegative(_retail.text);
    final w = parseNonNegative(_whole.text);
    return AlertDialog(
      title: const Text("Narxni o'zgartirish"),
      content: _DialogBody(error: _error, children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(widget.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        TextField(
          controller: _buy,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: _digits,
          onChanged: (_) => setState(() {}),
          decoration: inputDec('Kelish narxi'),
        ),
        TextField(
          controller: _retail,
          keyboardType: TextInputType.number,
          inputFormatters: _digits,
          onChanged: (_) => setState(() {}),
          decoration: inputDec('Chakana narxi'),
        ),
        TextField(
          controller: _whole,
          keyboardType: TextInputType.number,
          inputFormatters: _digits,
          onChanged: (_) => setState(() {}),
          decoration: inputDec('Ulgurji narxi'),
        ),
        if (b != null && r != null && w != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Chakana foyda: ${formatMoney(r - b)}\nUlgurji foyda: ${formatMoney(w - b)}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
      ]),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Bekor qilish')),
        FilledButton(onPressed: _busy ? null : _save, child: const Text('Saqlash')),
      ],
    );
  }
}
