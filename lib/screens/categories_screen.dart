import 'package:flutter/material.dart';
import '../core/data_bus.dart';
import '../core/utils.dart';
import '../models/records.dart';
import '../repositories/category_repository.dart';
import '../widgets/common.dart';
import 'products_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> _items = [];
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
      final r = await CategoryRepository.I.list();
      if (mounted) setState(() { _items = r; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<void> Function() f) async {
    try {
      await f();
    } on AppException catch (e) {
      if (mounted) showMsg(context, e.message, error: true);
    } catch (_) {
      if (mounted) showMsg(context, kGenericError, error: true);
    }
  }

  Future<void> _add() async {
    final n = await promptText(context, title: 'Yangi kategoriya', hint: 'Kategoriya nomi');
    if (n == null) return;
    await _run(() => CategoryRepository.I.add(n));
  }

  Future<void> _rename(Category c) async {
    final n = await promptText(context, title: 'Kategoriyani tahrirlash', initial: c.name);
    if (n == null) return;
    await _run(() => CategoryRepository.I.rename(c.id, n));
  }

  Future<void> _delete(Category c) async {
    final ok = await confirmDialog(context,
        title: "Kategoriyani o'chirish",
        message: '"${c.name}" o\'chiriladi. Undagi tovarlar "Kategoriyasiz" bo\'lib qoladi.',
        confirmText: "O'chirish",
        danger: true);
    if (!ok) return;
    await _run(() => CategoryRepository.I.delete(c.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kategoriyalar')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text("Kategoriya qo'shish"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const EmptyState(icon: Icons.category_outlined, text: "Kategoriya yo'q. Birinchisini qo'shing.")
              : Constrained(
                  maxWidth: 700,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final c = _items[i];
                      return AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        onTap: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ProductsScreen(standalone: true, categoryId: c.id, title: c.name)),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text('${c.count} ta tovar', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ]),
                          ),
                          IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Tahrirlash', onPressed: () => _rename(c)),
                          IconButton(icon: const Icon(Icons.delete_outline), tooltip: "O'chirish", onPressed: () => _delete(c)),
                        ]),
                      );
                    },
                  ),
                ),
    );
  }
}
