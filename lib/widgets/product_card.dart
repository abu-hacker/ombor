import 'package:flutter/material.dart';
import '../core/utils.dart';
import '../models/product.dart';
import '../screens/product_actions.dart';
import '../screens/product_detail_screen.dart';
import '../theme/app_theme.dart';
import 'common.dart';

class ProductTile extends StatelessWidget {
  final Product product;
  final bool compact;
  final VoidCallback? onTap;
  const ProductTile({super.key, required this.product, this.compact = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final cs = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 12, color: cs.onSurfaceVariant);
    final tap = onTap ?? () => openProductDetail(context, p.id!);

    if (compact) {
      return AppCard(
        onTap: tap,
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          ProductImage(path: p.imagePath, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('Qoldiq: ${p.quantity}', style: muted),
            ]),
          ),
          StatusChip(p.status),
        ]),
      );
    }

    final profit = p.retailProfit;
    return AppCard(
      onTap: tap,
      padding: const EdgeInsets.all(10),
      child: Row(children: [
        ProductImage(path: p.imagePath, size: 84),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Text('${p.categoryName ?? 'Kategoriyasiz'} · ${p.barcode ?? p.qrCode}',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: muted),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Kelish: ${formatMoney(p.purchasePrice)}  ·  Chakana: ${formatMoney(p.retailPrice)}', style: const TextStyle(fontSize: 12.5)),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Ulgurji: ${formatMoney(p.wholesalePrice)}  ·  Foyda: ${formatMoney(profit)}',
                    style: TextStyle(fontSize: 12.5, color: profit >= 0 ? AppTheme.okColor : AppTheme.outColor)),
              ),
              const SizedBox(height: 4),
              Row(children: [
                StatusChip(p.status),
                const SizedBox(width: 8),
                Text('Qoldiq: ${p.quantity}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ]),
            ],
          ),
        ),
        PopupMenuButton<ProductAction>(
          tooltip: 'Amallar',
          onSelected: (a) => runProductAction(context, p, a),
          itemBuilder: (_) => productMenuItems(p),
        ),
      ]),
    );
  }
}

List<PopupMenuEntry<ProductAction>> productMenuItems(Product p) => [
      if (!p.isArchived) ...const [
        PopupMenuItem(value: ProductAction.edit, child: Text('Tahrirlash')),
        PopupMenuItem(value: ProductAction.price, child: Text("Narxni o'zgartirish")),
        PopupMenuItem(value: ProductAction.stock, child: Text("Qoldiqni o'zgartirish")),
        PopupMenuItem(value: ProductAction.qr, child: Text("QR ko'rish")),
        PopupMenuItem(value: ProductAction.label, child: Text('Narx yorlig\'i')),
        PopupMenuItem(value: ProductAction.archive, child: Text('Arxivlash')),
      ] else ...const [
        PopupMenuItem(value: ProductAction.qr, child: Text("QR ko'rish")),
        PopupMenuItem(value: ProductAction.restore, child: Text('Arxivdan tiklash')),
      ],
      const PopupMenuItem(value: ProductAction.delete, child: Text("Butunlay o'chirish")),
    ];
