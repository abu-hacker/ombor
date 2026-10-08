import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/data_bus.dart';
import '../core/utils.dart';
import '../models/product.dart';
import '../models/records.dart';
import '../repositories/product_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import 'product_actions.dart';
import 'qr_dialog.dart';
import 'stock_dialogs.dart';

Future<void> openProductDetail(BuildContext context, int id) =>
    Navigator.push<void>(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: id)));

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _p;
  List<StockMovement> _moves = [];
  List<PriceEntry> _prices = [];
  bool _loading = true;

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
    try {
      final repo = ProductRepository.I;
      final p = await repo.findById(widget.productId);
      if (!mounted) return;
      if (p == null) {
        Navigator.of(context).maybePop();
        return;
      }
      final m = await repo.movements(p.id!);
      final pr = await repo.priceHistory(p.id!);
      if (!mounted) return;
      setState(() {
        _p = p;
        _moves = m;
        _prices = pr;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    if (_loading || p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: _loading ? const CircularProgressIndicator() : const Text(kGenericError)),
      );
    }
    final cs = Theme.of(context).colorScheme;
    final muted = TextStyle(color: cs.onSurfaceVariant, fontSize: 13);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tovar'),
        actions: [
          PopupMenuButton<ProductAction>(
            onSelected: (a) => runProductAction(context, p, a),
            itemBuilder: (_) => productMenuItems(p),
          ),
        ],
      ),
      body: Constrained(
        maxWidth: 760,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Center(child: ProductImage(path: p.imagePath, size: 180, radius: 22)),
          const SizedBox(height: 14),
          Text(p.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            StatusChip(p.status),
            if (p.isArchived) ...[
              const SizedBox(width: 8),
              const Chip(label: Text('Arxivda'), visualDensity: VisualDensity.compact),
            ],
          ]),
          const SizedBox(height: 4),
          Center(child: Text(p.categoryName ?? 'Kategoriyasiz', style: muted)),
          const SizedBox(height: 14),
          if (!p.isArchived)
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
                  onPressed: () => runProductAction(context, p, ProductAction.price),
                  icon: const Icon(Icons.sell_outlined),
                  label: const Text('Narx')),
              OutlinedButton.icon(
                  onPressed: () => runProductAction(context, p, ProductAction.stock),
                  icon: const Icon(Icons.tune),
                  label: const Text('Qoldiq')),
              OutlinedButton.icon(
                  onPressed: () => runProductAction(context, p, ProductAction.edit),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Tahrirlash')),
              OutlinedButton.icon(
                  onPressed: () => runProductAction(context, p, ProductAction.label),
                  icon: const Icon(Icons.local_offer_outlined),
                  label: const Text('Yorliq')),
            ]),
          const SectionTitle('Kodlar'),
          AppCard(
            child: Row(children: [
              GestureDetector(
                onTap: () => showQrDialog(context, p),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(4),
                  child: QrImageView(data: p.qrCode, version: QrVersions.auto, size: 96, backgroundColor: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Mahsulot kodi: ${p.productCode}', style: muted),
                  const SizedBox(height: 4),
                  Text('QR: ${p.qrCode}', style: muted),
                  if (p.barcode != null) ...[
                    const SizedBox(height: 4),
                    Text('Barcode: ${p.barcode}', style: muted),
                    const SizedBox(height: 6),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(4),
                      child: BarcodeWidget(
                        barcode: Barcode.code128(),
                        data: p.barcode!,
                        height: 44,
                        drawText: false,
                        color: Colors.black,
                        errorBuilder: (c, e) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ]),
              ),
            ]),
          ),
          const SectionTitle('Foyda kalkulyatori'),
          AppCard(
            child: Column(children: [
              _row('Kelish narxi', formatMoney(p.purchasePrice)),
              _row('Chakana narxi', formatMoney(p.retailPrice)),
              _row('Chakana foyda', formatMoney(p.retailProfit), color: p.retailProfit >= 0 ? AppTheme.okColor : AppTheme.outColor),
              _row('Ulgurji narxi', formatMoney(p.wholesalePrice)),
              _row('Ulgurji foyda', formatMoney(p.wholesaleProfit), color: p.wholesaleProfit >= 0 ? AppTheme.okColor : AppTheme.outColor),
              const Divider(),
              _row('Qoldiq', '${p.quantity} (min: ${p.minimumQuantity})'),
              _row('Ombordagi kelish qiymati', formatMoney(p.stockValue)),
              _row('Potensial chakana foyda', formatMoney(p.potentialRetailProfit), bold: true),
              _row('Potensial ulgurji foyda', formatMoney(p.potentialWholesaleProfit), bold: true),
            ]),
          ),
          if (p.note != null) ...[
            const SectionTitle('Izoh'),
            AppCard(child: SizedBox(width: double.infinity, child: Text(p.note!))),
          ],
          const SectionTitle('Qoldiq tarixi'),
          if (_moves.isEmpty)
            Text("Hozircha yozuv yo'q.", style: muted)
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (final m in _moves) _moveTile(m, muted),
              ]),
            ),
          const SectionTitle('Narx tarixi'),
          if (_prices.isEmpty)
            Text("Hozircha yozuv yo'q.", style: muted)
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (final e in _prices) _priceTile(e, muted),
              ]),
            ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _row(String l, String v, {Color? color, bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(l)),
          Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color)),
        ]),
      );

  Widget _moveTile(StockMovement m, TextStyle muted) {
    final sign = m.type == 'out' ? '-' : (m.type == 'adjust' ? '' : '+');
    final color = m.type == 'out' ? AppTheme.outColor : (m.type == 'adjust' ? null : AppTheme.okColor);
    return ListTile(
      dense: true,
      title: Text('${m.typeLabel}: $sign${m.quantity}   (${m.oldQuantity} → ${m.newQuantity})',
          style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      subtitle: Text([
        formatDate(m.createdAt),
        if (m.type == 'out' && m.reason != null) m.reason!,
        if (m.note != null) m.note!,
      ].join(' · '), style: muted),
    );
  }

  Widget _priceTile(PriceEntry e, TextStyle muted) {
    String part(String l, int? o, int n) => o == null || o == n ? '$l: ${formatInt(n)}' : '$l: ${formatInt(o)} → ${formatInt(n)}';
    return ListTile(
      dense: true,
      title: Text('${part('Kelish', e.oldPurchase, e.newPurchase)}   ${part('Chakana', e.oldRetail, e.newRetail)}',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${part('Ulgurji', e.oldWholesale, e.newWholesale)} · ${formatDate(e.createdAt)}', style: muted),
    );
  }
}
