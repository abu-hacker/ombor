import 'package:flutter/material.dart';
import '../core/data_bus.dart';
import '../core/utils.dart';
import '../models/product.dart';
import '../models/records.dart';
import '../repositories/category_repository.dart';
import '../repositories/product_repository.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  final bool standalone;
  final int? categoryId;
  final String? title;
  final StockFilter initialFilter;
  const ProductsScreen({
    super.key,
    this.standalone = false,
    this.categoryId,
    this.title,
    this.initialFilter = StockFilter.all,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _search = TextEditingController();
  StockFilter _filter = StockFilter.all;
  int? _categoryId;
  SortKey _sort = SortKey.newest;
  bool _asc = false;
  List<Product> _items = [];
  List<Category> _categories = [];
  bool _loading = true;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _categoryId = widget.categoryId;
    DataBus.I.addListener(_load);
    if (!widget.standalone) NavController.filterRequest.addListener(_onFilterRequest);
    _load();
  }

  @override
  void dispose() {
    DataBus.I.removeListener(_load);
    if (!widget.standalone) NavController.filterRequest.removeListener(_onFilterRequest);
    _search.dispose();
    super.dispose();
  }

  void _onFilterRequest() {
    final f = NavController.filterRequest.value;
    if (f == null) return;
    NavController.filterRequest.value = null;
    setState(() {
      _filter = f;
      _categoryId = null;
      _search.clear();
    });
    _load();
  }

  Future<void> _load() async {
    final my = ++_seq;
    try {
      final items = await ProductRepository.I.list(
        query: _search.text,
        filter: _filter,
        categoryId: _categoryId,
        sort: _sort,
        ascending: _asc,
      );
      final cats = await CategoryRepository.I.list();
      if (!mounted || my != _seq) return;
      setState(() {
        _items = items;
        _categories = cats;
        _loading = false;
      });
    } catch (_) {
      if (mounted && my == _seq) {
        setState(() => _loading = false);
        showMsg(context, kGenericError, error: true);
      }
    }
  }

  Future<void> _add() async {
    await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const ProductFormScreen()));
  }

  static const _filterLabels = {
    StockFilter.all: 'Barchasi',
    StockFilter.ok: 'Mavjud',
    StockFilter.low: 'Kam qolgan',
    StockFilter.out: 'Tugagan',
    StockFilter.archived: 'Arxivlangan',
  };

  static const _sortLabels = {
    SortKey.newest: 'Yangi qo\'shilgan',
    SortKey.name: 'Nomi bo\'yicha',
    SortKey.price: 'Narx bo\'yicha',
    SortKey.quantity: 'Qoldiq bo\'yicha',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'Tovarlar')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text("Tovar qo'shish"),
      ),
      body: Constrained(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => _load(),
                  decoration: inputDec('Qidirish: nom, kod, QR, barcode').copyWith(
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                              _load();
                            }),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<SortKey>(
                tooltip: 'Saralash',
                icon: Icon(_asc ? Icons.arrow_upward : Icons.arrow_downward),
                onSelected: (k) {
                  setState(() {
                    if (_sort == k) {
                      _asc = !_asc;
                    } else {
                      _sort = k;
                      _asc = k != SortKey.newest;
                    }
                  });
                  _load();
                },
                itemBuilder: (_) => [
                  for (final e in _sortLabels.entries)
                    CheckedPopupMenuItem(value: e.key, checked: _sort == e.key, child: Text(e.value)),
                ],
              ),
              PopupMenuButton<int>(
                tooltip: 'Kategoriya',
                icon: Icon(Icons.category_outlined, color: _categoryId != null ? cs.primary : null),
                onSelected: (v) {
                  setState(() => _categoryId = v == -1 ? null : v);
                  _load();
                },
                itemBuilder: (_) => [
                  CheckedPopupMenuItem(value: -1, checked: _categoryId == null, child: const Text('Barcha kategoriyalar')),
                  for (final c in _categories)
                    CheckedPopupMenuItem(value: c.id, checked: _categoryId == c.id, child: Text('${c.name} (${c.count})')),
                ],
              ),
            ]),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final e in _filterLabels.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(e.value),
                      selected: _filter == e.key,
                      onSelected: (_) {
                        setState(() => _filter = e.key);
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${_items.length} ta tovar', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? EmptyState(
                        icon: Icons.inventory_2_outlined,
                        text: _search.text.isNotEmpty ? 'Hech narsa topilmadi.' : "Bu bo'limda tovar yo'q.",
                        action: _filter == StockFilter.all && _search.text.isEmpty
                            ? FilledButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text("Tovar qo'shish"))
                            : null,
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 520,
                          mainAxisExtent: 128,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _items.length,
                        itemBuilder: (_, i) => ProductTile(product: _items[i]),
                      ),
          ),
        ]),
      ),
    );
  }
}
