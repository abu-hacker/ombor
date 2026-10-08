import 'package:flutter/material.dart';
import '../core/utils.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';
import 'label_screen.dart';
import 'product_form_screen.dart';
import 'qr_dialog.dart';
import 'stock_dialogs.dart';

enum ProductAction { edit, price, stock, qr, label, archive, restore, delete }

Future<void> runProductAction(BuildContext context, Product p, ProductAction a) async {
  final repo = ProductRepository.I;
  try {
    switch (a) {
      case ProductAction.edit:
        await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => ProductFormScreen(product: p)));
        break;
      case ProductAction.price:
        if (await showPriceDialog(context, p) && context.mounted) showMsg(context, "Narx o'zgartirildi.");
        break;
      case ProductAction.stock:
        if (await showAdjustDialog(context, p) && context.mounted) showMsg(context, "Qoldiq o'zgartirildi.");
        break;
      case ProductAction.qr:
        await showQrDialog(context, p);
        break;
      case ProductAction.label:
        await Navigator.push<void>(context, MaterialPageRoute(builder: (_) => LabelScreen(product: p)));
        break;
      case ProductAction.archive:
        if (await confirmDialog(context,
            title: 'Arxivlash',
            message: '"${p.name}" arxivga o\'tkaziladi. Keyin qayta tiklash mumkin.',
            confirmText: 'Arxivlash')) {
          await repo.setArchived(p.id!, true);
          if (context.mounted) showMsg(context, 'Arxivlandi.');
        }
        break;
      case ProductAction.restore:
        await repo.setArchived(p.id!, false);
        if (context.mounted) showMsg(context, 'Arxivdan tiklandi.');
        break;
      case ProductAction.delete:
        if (await confirmDialog(context,
            title: "Butunlay o'chirish",
            message: '"${p.name}" va uning barcha tarixi butunlay o\'chiriladi. Bu amalni qaytarib bo\'lmaydi.',
            confirmText: "O'chirish",
            danger: true)) {
          await repo.deletePermanently(p.id!);
          if (context.mounted) showMsg(context, "Mahsulot o'chirildi.");
        }
        break;
    }
  } on AppException catch (e) {
    if (context.mounted) showMsg(context, e.message, error: true);
  } catch (_) {
    if (context.mounted) showMsg(context, kGenericError, error: true);
  }
}
