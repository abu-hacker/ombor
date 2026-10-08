import 'package:flutter/material.dart';
import '../core/data_bus.dart';
import '../core/utils.dart';
import '../models/product.dart';
import '../models/records.dart';
import '../repositories/product_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import '../widgets/product_picker.dart';
import 'product_form_screen.dart';
import 'stock_dialogs.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Stats? _stats;
  List<Product> _recent = [];
  List<Product> _low = [];
  List<Product> _out = [];
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
      final s = await repo.stats();
      final r = await repo.list(sort: SortKey.newest, limit: 5);
      final l = await repo.list(filter: StockFilter.low, sort: SortKey.quantity, ascending: true, limit: 5);
      final o = await repo.list(filter: StockFilter.out, limit: 5);
      if (!mounted) return;
      setState(() {
        _stats = s;
        _recent = r;
        _low = l;
        _out = o;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() => Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const ProductFormScreen()));

  Future<void> _move(bool isIn) async {
    final p = await pickProduct(context);
    if (p == null || !mounted) return;
    final ok = isIn ? await showStockInDialog(context, p) : await showStockOutDialog(context, p);
    if (ok && mounted) showMsg(context, isIn ? 'Kirim saqlandi.' : 'Chiqim saqlandi.');
  }

  @override
  Widget build(BuildContext context) {
    final s = _stats;
    return Scaffold(
      appBar: AppBar(title: const Text('Bosh sahifa')),
      body: _loading || s == null
          ? const Center(child: CircularProgressIndicator())
          : Constrained(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  StatGrid(children: [
                    StatCard(icon: Icons.inventory_2_outlined, label: 'Jami tovarlar', value: formatInt(s.totalProducts)),
                    StatCard(icon: Icons.layers_outlined, label: 'Jami qoldiq', value: formatInt(s.totalQuantity)),
                    StatCard(icon: Icons.warehouse_outlined, label: 'Ombor kelish qiymati', value: formatMoney(s.stockValue)),
                    StatCard(icon: Icons.trending_up, label: 'Potensial foyda', value: formatMoney(s.retailProfit), color: AppTheme.okColor),
                    StatCard(
                        icon: Icons.warning_amber_rounded,
                        label: 'Kam qolgan',
                        value: formatInt(s.lowCount),
                        color: AppTheme.lowColor,
                        onTap: () => NavController.openProducts(StockFilter.low)),
                    StatCard(
                        icon: Icons.remove_shopping_cart_outlined,
                        label: 'Tugagan',
                        value: formatInt(s.outCount),
                        color: AppTheme.outColor,
                        onTap: () => NavController.openProducts(StockFilter.out)),
                  ]),
                  const SectionTitle('Tezkor amallar'),
                  Row(children: [
                    Expanded(child: _Quick(icon: Icons.add_circle_outline, label: "Tovar qo'shish", onTap: _add)),
                    const SizedBox(width: 8),
                    Expanded(child: _Quick(icon: Icons.qr_code_scanner, label: 'QR skaner', onTap: () => NavController.go(2))),
                    const SizedBox(width: 8),
                    Expanded(child: _Quick(icon: Icons.download, label: 'Tovar kirimi', onTap: () => _move(true))),
                    const SizedBox(width: 8),
                    Expanded(child: _Quick(icon: Icons.upload, label: 'Tovar chiqimi', onTap: () => _move(false))),
                  ]),
                  _section('Oxirgi qo\'shilgan tovarlar', _recent, "Hali tovar qo'shilmagan.", null),
                  _section('Kam qolgan tovarlar', _low, "Kam qolgan tovar yo'q.", StockFilter.low),
                  _section('Tugagan tovarlar', _out, "Tugagan tovar yo'q.", StockFilter.out),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
    );
  }

  Widget _section(String title, List<Product> items, String empty, StockFilter? all) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle(title,
          trailing: TextButton(
              onPressed: () => NavController.openProducts(all ?? StockFilter.all), child: const Text('Barchasi'))),
      if (items.isEmpty)
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(empty, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        )
      else
        for (final p in items)
          Padding(padding: const EdgeInsets.only(bottom: 8), child: ProductTile(product: p, compact: true)),
    ]);
  }
}

class _Quick extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Quick({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Column(children: [
        Icon(icon, color: cs.primary, size: 26),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
