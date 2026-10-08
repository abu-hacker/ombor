import 'package:flutter/material.dart';
import '../core/data_bus.dart';
import '../core/utils.dart';
import '../models/records.dart';
import '../repositories/product_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Stats? _s;
  List<CategoryStat> _cats = [];
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
      final s = await ProductRepository.I.stats();
      final c = await ProductRepository.I.categoryStats();
      if (!mounted) return;
      setState(() {
        _s = s;
        _cats = c;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return Scaffold(
      appBar: AppBar(title: const Text('Statistika')),
      body: _loading || s == null
          ? const Center(child: CircularProgressIndicator())
          : Constrained(
              maxWidth: 900,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                StatGrid(children: [
                  StatCard(icon: Icons.inventory_2_outlined, label: 'Jami mahsulot', value: formatInt(s.totalProducts)),
                  StatCard(icon: Icons.layers_outlined, label: 'Jami qoldiq', value: formatInt(s.totalQuantity)),
                  StatCard(icon: Icons.warehouse_outlined, label: 'Omborning kelish qiymati', value: formatMoney(s.stockValue)),
                  StatCard(icon: Icons.category_outlined, label: 'Kategoriyalar soni', value: formatInt(s.categoryCount)),
                  StatCard(icon: Icons.trending_up, label: 'Potensial chakana foyda', value: formatMoney(s.retailProfit), color: AppTheme.okColor),
                  StatCard(icon: Icons.trending_up, label: 'Potensial ulgurji foyda', value: formatMoney(s.wholesaleProfit), color: AppTheme.okColor),
                  StatCard(icon: Icons.warning_amber_rounded, label: 'Kam qolganlar', value: formatInt(s.lowCount), color: AppTheme.lowColor),
                  StatCard(icon: Icons.remove_shopping_cart_outlined, label: 'Tugaganlar', value: formatInt(s.outCount), color: AppTheme.outColor),
                ]),
                const SectionTitle('Tovarlar holati'),
                AppCard(child: _statusBar(s)),
                const SectionTitle("Kategoriyalar bo'yicha tovarlar"),
                AppCard(
                  child: _cats.isEmpty
                      ? const Text("Ma'lumot yo'q.")
                      : Column(children: [
                          for (final c in _cats)
                            _bar(c.name, c.count, _cats.first.count == 0 ? 1 : _cats.first.count, '${c.count} ta · ${formatMoney(c.value)}'),
                        ]),
                ),
                const SizedBox(height: 24),
              ]),
            ),
    );
  }

  Widget _statusBar(Stats s) {
    final total = s.totalProducts == 0 ? 1 : s.totalProducts;
    Widget seg(int n, Color c) => n == 0
        ? const SizedBox.shrink()
        : Expanded(flex: n, child: Container(height: 18, color: c));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: s.totalProducts == 0
            ? Container(height: 18, color: Colors.grey.shade400)
            : Row(children: [seg(s.okCount, AppTheme.okColor), seg(s.lowCount, AppTheme.lowColor), seg(s.outCount, AppTheme.outColor)]),
      ),
      const SizedBox(height: 10),
      Wrap(spacing: 16, runSpacing: 4, children: [
        _legend(AppTheme.okColor, 'Mavjud: ${s.okCount} (${(s.okCount * 100 / total).round()}%)'),
        _legend(AppTheme.lowColor, 'Kam qolgan: ${s.lowCount}'),
        _legend(AppTheme.outColor, 'Tugagan: ${s.outCount}'),
      ]),
    ]);
  }

  Widget _legend(Color c, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(t, style: const TextStyle(fontSize: 12.5)),
      ]);

  Widget _bar(String label, int value, int max, String trailing) {
    final cs = Theme.of(context).colorScheme;
    final frac = max == 0 ? 0.0 : (value / max).clamp(0.02, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(trailing, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: frac.toDouble(), minHeight: 10, backgroundColor: cs.surfaceContainerHighest),
        ),
      ]),
    );
  }
}
