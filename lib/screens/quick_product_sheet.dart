import 'package:flutter/material.dart';
import '../core/data_bus.dart';
import '../core/utils.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'product_detail_screen.dart';
import 'stock_dialogs.dart';

/// Skanerdan keyin chiqadigan "Tezkor mahsulot oynasi".
Future<void> showQuickProductSheet(BuildContext context, int productId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => _QuickSheet(productId: productId),
  );
}

class _QuickSheet extends StatefulWidget {
  final int productId;
  const _QuickSheet({required this.productId});
  @override
  State<_QuickSheet> createState() => _QuickSheetState();
}

class _QuickSheetState extends State<_QuickSheet> {
  Product? _p;

  @override
  void initState() {
    super.initState();
    DataBus.I.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    DataBus.I.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final p = await ProductRepository.I.findById(widget.productId);
    if (mounted) setState(() => _p = p);
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    if (p == null) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }
    final cs = Theme.of(context).colorScheme;
    Widget row(String l, String v, {Color? c}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(child: Text(l, style: TextStyle(color: cs.onSurfaceVariant))),
            Text(v, style: TextStyle(fontWeight: FontWeight.w700, color: c)),
          ]),
        );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            ProductImage(path: p.imagePath, size: 88, radius: 16),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Row(children: [
                  StatusChip(p.status),
                  if (p.isArchived) const Padding(padding: EdgeInsets.only(left: 6), child: Text('(arxivda)')),
                ]),
                const SizedBox(height: 4),
                Text('Qoldiq: ${p.quantity}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          row('Kelish narxi', formatMoney(p.purchasePrice)),
          row('Chakana narxi', formatMoney(p.retailPrice)),
          row('Ulgurji narxi', formatMoney(p.wholesalePrice)),
          row('Chakana foyda', formatMoney(p.retailProfit), c: p.retailProfit >= 0 ? AppTheme.okColor : AppTheme.outColor),
          row('Ulgurji foyda', formatMoney(p.wholesaleProfit), c: p.wholesaleProfit >= 0 ? AppTheme.okColor : AppTheme.outColor),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            FilledButton.icon(
                onPressed: () async {
                  if (await showStockInDialog(context, p) && context.mounted) showMsg(context, 'Kirim saqlandi.');
                },
                icon: const Icon(Icons.download),
                label: const Text('Kirim')),
            FilledButton.tonalIcon(
                onPressed: () async {
                  if (await showStockOutDialog(context, p) && context.mounted) showMsg(context, 'Chiqim saqlandi.');
                },
                icon: const Icon(Icons.upload),
                label: const Text('Chiqim')),
            OutlinedButton.icon(
                onPressed: () async {
                  if (await showPriceDialog(context, p) && context.mounted) showMsg(context, "Narx o'zgartirildi.");
                },
                icon: const Icon(Icons.sell_outlined),
                label: const Text('Narx')),
            OutlinedButton.icon(
                onPressed: () async {
                  if (await showAdjustDialog(context, p) && context.mounted) showMsg(context, "Qoldiq o'zgartirildi.");
                },
                icon: const Icon(Icons.tune),
                label: const Text('Qoldiq')),
          ]),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              final nav = Navigator.of(context);
              final id = p.id!;
              nav.pop();
              openProductDetail(nav.context, id);
            },
            child: const Text('Batafsil'),
          ),
        ]),
      ),
    );
  }
}
