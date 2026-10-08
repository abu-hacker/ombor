import 'package:flutter/material.dart';
import '../core/utils.dart';
import '../models/records.dart';
import '../repositories/product_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryEntry> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await ProductRepository.I.history();
      if (mounted) setState(() { _items = r; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _icon(String a) {
    switch (a) {
      case 'created':
        return Icons.add_circle_outline;
      case 'deleted':
        return Icons.delete_outline;
      case 'archived':
        return Icons.archive_outlined;
      case 'restored':
        return Icons.unarchive_outlined;
      case 'price_changed':
        return Icons.sell_outlined;
      case 'stock_in':
        return Icons.download;
      case 'stock_out':
        return Icons.upload;
      case 'stock_adjusted':
        return Icons.tune;
      default:
        return Icons.edit_outlined;
    }
  }

  Color? _color(String a) {
    switch (a) {
      case 'deleted':
      case 'stock_out':
        return AppTheme.outColor;
      case 'created':
      case 'stock_in':
      case 'restored':
        return AppTheme.okColor;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Scaffold(
      appBar: AppBar(title: const Text('Tarix')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const EmptyState(icon: Icons.history, text: "Tarix hozircha bo'sh.")
              : Constrained(
                  maxWidth: 760,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final e = _items[i];
                      return AppCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(_icon(e.action), color: _color(e.action)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${e.actionLabel}: ${e.productName}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (e.details != null) Text(e.details!, style: muted),
                              Text(formatDate(e.createdAt), style: muted),
                            ]),
                          ),
                        ]),
                      );
                    },
                  ),
                ),
    );
  }
}
