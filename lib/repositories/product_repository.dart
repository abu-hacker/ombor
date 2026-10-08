import 'dart:math';
import 'package:sqflite/sqflite.dart';
import '../core/data_bus.dart';
import '../core/utils.dart';
import '../database/app_database.dart';
import '../models/product.dart';
import '../models/records.dart';
import '../services/image_service.dart';

class ProductRepository {
  ProductRepository._();
  static final ProductRepository I = ProductRepository._();

  Future<Database> get _db => AppDatabase.instance;

  static const String _select =
      'SELECT p.*, c.name AS category_name FROM products p LEFT JOIN categories c ON c.id = p.category_id';

  // ---------------------------------------------------------------- queries

  Future<List<Product>> list({
    String query = '',
    StockFilter filter = StockFilter.all,
    int? categoryId,
    SortKey sort = SortKey.newest,
    bool ascending = false,
    int? limit,
  }) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];

    where.add(filter == StockFilter.archived
        ? 'p.is_archived = 1'
        : 'p.is_archived = 0');
    switch (filter) {
      case StockFilter.ok:
        where.add('p.quantity > 0 AND p.quantity > p.minimum_quantity');
        break;
      case StockFilter.low:
        where.add('p.quantity > 0 AND p.quantity <= p.minimum_quantity');
        break;
      case StockFilter.out:
        where.add('p.quantity <= 0');
        break;
      default:
        break;
    }
    if (categoryId != null) {
      where.add('p.category_id = ?');
      args.add(categoryId);
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      where.add('(p.search_key LIKE ? OR LOWER(p.product_code) LIKE ? '
          "OR LOWER(p.qr_code) LIKE ? OR LOWER(IFNULL(p.barcode, '')) LIKE ? "
          "OR LOWER(IFNULL(c.name, '')) LIKE ?)");
      final like = '%$q%';
      args.addAll([like, like, like, like, like]);
    }

    final col = switch (sort) {
      SortKey.name => 'p.search_key',
      SortKey.price => 'p.retail_price',
      SortKey.quantity => 'p.quantity',
      SortKey.newest => 'p.id',
    };
    final dir = ascending ? 'ASC' : 'DESC';
    final sql = '$_select WHERE ${where.join(' AND ')} ORDER BY $col $dir'
        '${limit != null ? ' LIMIT $limit' : ''}';
    final rows = await db.rawQuery(sql, args);
    return rows.map(Product.fromMap).toList();
  }

  Future<Product?> findById(int id) async {
    final db = await _db;
    final rows = await db.rawQuery('$_select WHERE p.id = ?', [id]);
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  /// QR, barcode yoki mahsulot kodi bo'yicha topish.
  Future<Product?> findByCode(String code) async {
    final c = code.trim();
    if (c.isEmpty) return null;
    final db = await _db;
    final rows = await db.rawQuery(
        '$_select WHERE LOWER(p.qr_code) = LOWER(?) OR LOWER(p.barcode) = LOWER(?) '
        'OR LOWER(p.product_code) = LOWER(?) LIMIT 1',
        [c, c, c]);
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<List<StockMovement>> movements(int productId, {int limit = 100}) async {
    final db = await _db;
    final rows = await db.query('stock_movements',
        where: 'product_id = ?',
        whereArgs: [productId],
        orderBy: 'id DESC',
        limit: limit);
    return rows.map(StockMovement.fromMap).toList();
  }

  Future<List<PriceEntry>> priceHistory(int productId, {int limit = 100}) async {
    final db = await _db;
    final rows = await db.query('price_history',
        where: 'product_id = ?',
        whereArgs: [productId],
        orderBy: 'id DESC',
        limit: limit);
    return rows.map(PriceEntry.fromMap).toList();
  }

  Future<List<HistoryEntry>> history({int limit = 500}) async {
    final db = await _db;
    final rows = await db.query('product_history',
        orderBy: 'id DESC', limit: limit);
    return rows.map(HistoryEntry.fromMap).toList();
  }

  Future<Stats> stats() async {
    final db = await _db;
    final r = (await db.rawQuery('''
SELECT COUNT(*) AS c,
  IFNULL(SUM(quantity), 0) AS q,
  IFNULL(SUM(quantity * purchase_price), 0) AS v,
  IFNULL(SUM(quantity * (retail_price - purchase_price)), 0) AS rp,
  IFNULL(SUM(quantity * (wholesale_price - purchase_price)), 0) AS wp,
  IFNULL(SUM(CASE WHEN quantity > 0 AND quantity <= minimum_quantity THEN 1 ELSE 0 END), 0) AS low,
  IFNULL(SUM(CASE WHEN quantity <= 0 THEN 1 ELSE 0 END), 0) AS outc
FROM products WHERE is_archived = 0''')).first;
    final cc = (await db.rawQuery('SELECT COUNT(*) AS c FROM categories')).first;
    int n(Object? v) => (v as num).toInt();
    return Stats(
      totalProducts: n(r['c']),
      totalQuantity: n(r['q']),
      stockValue: n(r['v']),
      retailProfit: n(r['rp']),
      wholesaleProfit: n(r['wp']),
      lowCount: n(r['low']),
      outCount: n(r['outc']),
      categoryCount: n(cc['c']),
    );
  }

  Future<List<CategoryStat>> categoryStats() async {
    final db = await _db;
    final rows = await db.rawQuery('''
SELECT IFNULL(c.name, 'Kategoriyasiz') AS name, COUNT(p.id) AS cnt,
  IFNULL(SUM(p.quantity * p.purchase_price), 0) AS val
FROM products p LEFT JOIN categories c ON c.id = p.category_id
WHERE p.is_archived = 0
GROUP BY p.category_id ORDER BY cnt DESC LIMIT 10''');
    return rows
        .map((r) => CategoryStat(r['name'] as String, (r['cnt'] as num).toInt(),
            (r['val'] as num).toInt()))
        .toList();
  }

  // ------------------------------------------------------------ code helpers

  static const String _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  Future<String> newProductCode() async {
    final db = await _db;
    final r = await db.rawQuery('SELECT IFNULL(MAX(id), 0) AS m FROM products');
    var n = (r.first['m'] as num).toInt() + 1;
    while (true) {
      final code = 'P${n.toString().padLeft(5, '0')}';
      if (!await _codeUsed(db, code)) return code;
      n++;
    }
  }

  Future<String> newQrCode() async {
    final db = await _db;
    final rnd = Random.secure();
    while (true) {
      final code = 'TB${List.generate(8, (_) => _alphabet[rnd.nextInt(_alphabet.length)]).join()}';
      if (!await _codeUsed(db, code)) return code;
    }
  }

  Future<bool> _codeUsed(DatabaseExecutor ex, String code) async {
    final r = await ex.rawQuery(
        'SELECT 1 FROM products WHERE product_code = ? OR qr_code = ? OR barcode = ? LIMIT 1',
        [code, code, code]);
    return r.isNotEmpty;
  }

  // -------------------------------------------------------------- validation

  void _validate(Product p) {
    if (p.name.trim().isEmpty) throw AppException('Mahsulot nomini kiriting.');
    if (p.purchasePrice < 0 || p.retailPrice < 0 || p.wholesalePrice < 0) {
      throw AppException('Narxni tekshiring.');
    }
    if (p.quantity < 0) throw AppException("Qoldiq manfiy bo'lishi mumkin emas.");
    if (p.minimumQuantity < 0) {
      throw AppException("Minimal qoldiq manfiy bo'lishi mumkin emas.");
    }
    if (p.productCode.trim().isEmpty) {
      throw AppException('Mahsulot kodini kiriting.');
    }
    if (p.qrCode.trim().isEmpty) throw AppException('QR kodni kiriting.');
  }

  Future<void> _checkUnique(DatabaseExecutor ex, Product p) async {
    final self = p.id ?? -1;
    final checks = <String, String?>{
      'mahsulot kodi': p.productCode,
      'QR kod': p.qrCode,
      'Barcode': p.barcode,
    };
    for (final e in checks.entries) {
      final v = e.value;
      if (v == null || v.isEmpty) continue;
      final rows = await ex.rawQuery(
          'SELECT id FROM products WHERE id != ? AND (product_code = ? OR qr_code = ? OR barcode = ?) LIMIT 1',
          [self, v, v, v]);
      if (rows.isNotEmpty) {
        throw AppException('Takroriy ${e.key}: "$v" boshqa mahsulotda ishlatilgan.');
      }
    }
  }

  Future<Product> _load(DatabaseExecutor ex, int id) async {
    final rows = await ex.rawQuery('$_select WHERE p.id = ?', [id]);
    if (rows.isEmpty) throw AppException('Mahsulot topilmadi.');
    return Product.fromMap(rows.first);
  }

  Future<void> _log(DatabaseExecutor ex, int? id, String name, String action,
      String? details, String now) async {
    await ex.insert('product_history', {
      'product_id': id,
      'product_name': name,
      'action': action,
      'details': details,
      'created_at': now,
    });
  }

  Future<void> _priceRow(DatabaseExecutor ex, int id, Product? old, Product now,
      String ts) async {
    await ex.insert('price_history', {
      'product_id': id,
      'old_purchase_price': old?.purchasePrice,
      'new_purchase_price': now.purchasePrice,
      'old_retail_price': old?.retailPrice,
      'new_retail_price': now.retailPrice,
      'old_wholesale_price': old?.wholesalePrice,
      'new_wholesale_price': now.wholesalePrice,
      'created_at': ts,
    });
  }

  // ------------------------------------------------------------------ writes

  Future<int> add(Product p) async {
    p.barcode = (p.barcode ?? '').trim().isEmpty ? null : p.barcode!.trim();
    p.productCode = p.productCode.trim();
    p.qrCode = p.qrCode.trim();
    p.name = p.name.trim();
    _validate(p);
    final db = await _db;
    final now = nowIso();
    late int id;
    await db.transaction((txn) async {
      await _checkUnique(txn, p);
      final m = p.toMap()..remove('id');
      m['created_at'] = now;
      m['updated_at'] = now;
      id = await txn.insert('products', m);
      if (p.quantity > 0) {
        await txn.insert('stock_movements', {
          'product_id': id,
          'type': 'initial',
          'quantity': p.quantity,
          'old_quantity': 0,
          'new_quantity': p.quantity,
          'purchase_price': p.purchasePrice,
          'reason': "Boshlang'ich qoldiq",
          'note': null,
          'created_at': now,
        });
      }
      await _priceRow(txn, id, null, p, now);
      await _log(txn, id, p.name, 'created', "Tovar qo'shildi", now);
    });
    DataBus.I.changed();
    return id;
  }

  Future<void> update(Product p) async {
    if (p.id == null) throw AppException('Mahsulot topilmadi.');
    p.barcode = (p.barcode ?? '').trim().isEmpty ? null : p.barcode!.trim();
    p.productCode = p.productCode.trim();
    p.qrCode = p.qrCode.trim();
    p.name = p.name.trim();
    _validate(p);
    final db = await _db;
    final now = nowIso();
    await db.transaction((txn) async {
      final old = await _load(txn, p.id!);
      await _checkUnique(txn, p);
      final m = p.toMap();
      m['created_at'] = old.createdAt;
      m['updated_at'] = now;
      await txn.update('products', m, where: 'id = ?', whereArgs: [p.id]);

      final priceChanged = old.purchasePrice != p.purchasePrice ||
          old.retailPrice != p.retailPrice ||
          old.wholesalePrice != p.wholesalePrice;
      if (priceChanged) {
        await _priceRow(txn, p.id!, old, p, now);
        await _log(
            txn,
            p.id,
            p.name,
            'price_changed',
            'Kelish ${formatInt(old.purchasePrice)}→${formatInt(p.purchasePrice)}, '
                'chakana ${formatInt(old.retailPrice)}→${formatInt(p.retailPrice)}, '
                'ulgurji ${formatInt(old.wholesalePrice)}→${formatInt(p.wholesalePrice)}',
            now);
      }
      if (old.quantity != p.quantity) {
        await txn.insert('stock_movements', {
          'product_id': p.id,
          'type': 'adjust',
          'quantity': (p.quantity - old.quantity).abs(),
          'old_quantity': old.quantity,
          'new_quantity': p.quantity,
          'purchase_price': null,
          'reason': "Qo'lda tuzatish",
          'note': null,
          'created_at': now,
        });
        await _log(txn, p.id, p.name, 'stock_adjusted',
            '${old.quantity} → ${p.quantity}', now);
      }
      final metaChanged = old.name != p.name ||
          old.categoryId != p.categoryId ||
          old.productCode != p.productCode ||
          old.qrCode != p.qrCode ||
          old.barcode != p.barcode ||
          old.imagePath != p.imagePath ||
          old.note != p.note ||
          old.minimumQuantity != p.minimumQuantity;
      if (metaChanged) {
        await _log(txn, p.id, p.name, 'updated', 'Tovar ma\'lumotlari tahrirlandi', now);
      }
    });
    DataBus.I.changed();
  }

  Future<void> stockIn({
    required int productId,
    required int quantity,
    required int purchasePrice,
    DateTime? date,
    String? note,
  }) async {
    if (quantity <= 0) throw AppException('Miqdorni tekshiring.');
    if (purchasePrice < 0) throw AppException('Narxni tekshiring.');
    final db = await _db;
    final ts = (date ?? DateTime.now()).toIso8601String();
    await db.transaction((txn) async {
      final p = await _load(txn, productId);
      final newQty = p.quantity + quantity;
      final updated = p.copyWith(purchasePrice: purchasePrice);
      await txn.update(
          'products',
          {
            'quantity': newQty,
            'purchase_price': purchasePrice,
            'updated_at': nowIso(),
          },
          where: 'id = ?',
          whereArgs: [productId]);
      if (purchasePrice != p.purchasePrice) {
        await _priceRow(txn, productId, p, updated, ts);
      }
      await txn.insert('stock_movements', {
        'product_id': productId,
        'type': 'in',
        'quantity': quantity,
        'old_quantity': p.quantity,
        'new_quantity': newQty,
        'purchase_price': purchasePrice,
        'reason': 'Kirim',
        'note': (note ?? '').trim().isEmpty ? null : note!.trim(),
        'created_at': ts,
      });
      await _log(txn, productId, p.name, 'stock_in',
          '+$quantity (${p.quantity} → $newQty)', ts);
    });
    DataBus.I.changed();
  }

  Future<void> stockOut({
    required int productId,
    required int quantity,
    required String reason,
    DateTime? date,
    String? note,
  }) async {
    if (quantity <= 0) throw AppException('Miqdorni tekshiring.');
    if (reason.trim().isEmpty) throw AppException('Sababni tanlang.');
    final db = await _db;
    final ts = (date ?? DateTime.now()).toIso8601String();
    await db.transaction((txn) async {
      final p = await _load(txn, productId);
      if (quantity > p.quantity) {
        throw AppException("Yetarli qoldiq yo'q. Hozirgi qoldiq: ${p.quantity}");
      }
      final newQty = p.quantity - quantity;
      await txn.update('products', {'quantity': newQty, 'updated_at': nowIso()},
          where: 'id = ?', whereArgs: [productId]);
      await txn.insert('stock_movements', {
        'product_id': productId,
        'type': 'out',
        'quantity': quantity,
        'old_quantity': p.quantity,
        'new_quantity': newQty,
        'purchase_price': p.purchasePrice,
        'reason': reason,
        'note': (note ?? '').trim().isEmpty ? null : note!.trim(),
        'created_at': ts,
      });
      await _log(txn, productId, p.name, 'stock_out',
          '-$quantity: $reason (${p.quantity} → $newQty)', ts);
    });
    DataBus.I.changed();
  }

  Future<void> adjustStock({
    required int productId,
    required int newQuantity,
    String? note,
  }) async {
    if (newQuantity < 0) {
      throw AppException("Qoldiq manfiy bo'lishi mumkin emas.");
    }
    final db = await _db;
    final ts = nowIso();
    await db.transaction((txn) async {
      final p = await _load(txn, productId);
      if (p.quantity == newQuantity) return;
      await txn.update('products', {'quantity': newQuantity, 'updated_at': ts},
          where: 'id = ?', whereArgs: [productId]);
      await txn.insert('stock_movements', {
        'product_id': productId,
        'type': 'adjust',
        'quantity': (newQuantity - p.quantity).abs(),
        'old_quantity': p.quantity,
        'new_quantity': newQuantity,
        'purchase_price': null,
        'reason': "Qo'lda tuzatish",
        'note': (note ?? '').trim().isEmpty ? null : note!.trim(),
        'created_at': ts,
      });
      await _log(txn, productId, p.name, 'stock_adjusted',
          '${p.quantity} → $newQuantity', ts);
    });
    DataBus.I.changed();
  }

  Future<void> setArchived(int id, bool archived) async {
    final db = await _db;
    final ts = nowIso();
    await db.transaction((txn) async {
      final p = await _load(txn, id);
      await txn.update('products',
          {'is_archived': archived ? 1 : 0, 'updated_at': ts},
          where: 'id = ?', whereArgs: [id]);
      await _log(txn, id, p.name, archived ? 'archived' : 'restored', null, ts);
    });
    DataBus.I.changed();
  }

  Future<void> deletePermanently(int id) async {
    final db = await _db;
    final ts = nowIso();
    String? image;
    await db.transaction((txn) async {
      final p = await _load(txn, id);
      image = p.imagePath;
      await txn.delete('products', where: 'id = ?', whereArgs: [id]);
      await _log(txn, id, p.name, 'deleted', null, ts);
    });
    await ImageService.delete(image);
    DataBus.I.changed();
  }
}
