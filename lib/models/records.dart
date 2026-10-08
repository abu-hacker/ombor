int _i(Object? v) => v == null ? 0 : (v as num).toInt();
int? _n(Object? v) => v == null ? null : (v as num).toInt();

class Category {
  final int id;
  final String name;
  final int count;
  Category({required this.id, required this.name, this.count = 0});

  factory Category.fromMap(Map<String, Object?> m) => Category(
        id: _i(m['id']),
        name: m['name'] as String,
        count: _i(m['cnt']),
      );
}

class StockMovement {
  final int id;
  final int productId;
  final String type; // initial, in, out, adjust
  final int quantity;
  final int oldQuantity;
  final int newQuantity;
  final int? purchasePrice;
  final String? reason;
  final String? note;
  final String createdAt;

  StockMovement({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.oldQuantity,
    required this.newQuantity,
    this.purchasePrice,
    this.reason,
    this.note,
    required this.createdAt,
  });

  factory StockMovement.fromMap(Map<String, Object?> m) => StockMovement(
        id: _i(m['id']),
        productId: _i(m['product_id']),
        type: m['type'] as String,
        quantity: _i(m['quantity']),
        oldQuantity: _i(m['old_quantity']),
        newQuantity: _i(m['new_quantity']),
        purchasePrice: _n(m['purchase_price']),
        reason: m['reason'] as String?,
        note: m['note'] as String?,
        createdAt: m['created_at'] as String,
      );

  String get typeLabel {
    switch (type) {
      case 'initial':
        return "Boshlang'ich qoldiq";
      case 'in':
        return 'Kirim';
      case 'out':
        return 'Chiqim';
      default:
        return "Qo'lda tuzatish";
    }
  }
}

class PriceEntry {
  final int id;
  final int? oldPurchase;
  final int newPurchase;
  final int? oldRetail;
  final int newRetail;
  final int? oldWholesale;
  final int newWholesale;
  final String createdAt;

  PriceEntry({
    required this.id,
    this.oldPurchase,
    required this.newPurchase,
    this.oldRetail,
    required this.newRetail,
    this.oldWholesale,
    required this.newWholesale,
    required this.createdAt,
  });

  factory PriceEntry.fromMap(Map<String, Object?> m) => PriceEntry(
        id: _i(m['id']),
        oldPurchase: _n(m['old_purchase_price']),
        newPurchase: _i(m['new_purchase_price']),
        oldRetail: _n(m['old_retail_price']),
        newRetail: _i(m['new_retail_price']),
        oldWholesale: _n(m['old_wholesale_price']),
        newWholesale: _i(m['new_wholesale_price']),
        createdAt: m['created_at'] as String,
      );
}

class HistoryEntry {
  final int id;
  final int? productId;
  final String productName;
  final String action;
  final String? details;
  final String createdAt;

  HistoryEntry({
    required this.id,
    this.productId,
    required this.productName,
    required this.action,
    this.details,
    required this.createdAt,
  });

  factory HistoryEntry.fromMap(Map<String, Object?> m) => HistoryEntry(
        id: _i(m['id']),
        productId: _n(m['product_id']),
        productName: (m['product_name'] as String?) ?? '',
        action: m['action'] as String,
        details: m['details'] as String?,
        createdAt: m['created_at'] as String,
      );

  String get actionLabel {
    switch (action) {
      case 'created':
        return "Tovar qo'shildi";
      case 'updated':
        return 'Tovar tahrirlandi';
      case 'deleted':
        return "Tovar o'chirildi";
      case 'archived':
        return 'Tovar arxivlandi';
      case 'restored':
        return 'Tovar arxivdan tiklandi';
      case 'price_changed':
        return "Narx o'zgardi";
      case 'stock_in':
        return 'Kirim qilindi';
      case 'stock_out':
        return 'Chiqim qilindi';
      case 'stock_adjusted':
        return 'Qoldiq tuzatildi';
      default:
        return action;
    }
  }
}

class Stats {
  final int totalProducts;
  final int totalQuantity;
  final int stockValue;
  final int retailProfit;
  final int wholesaleProfit;
  final int lowCount;
  final int outCount;
  final int categoryCount;

  Stats({
    required this.totalProducts,
    required this.totalQuantity,
    required this.stockValue,
    required this.retailProfit,
    required this.wholesaleProfit,
    required this.lowCount,
    required this.outCount,
    required this.categoryCount,
  });

  int get okCount => totalProducts - lowCount - outCount;
}

class CategoryStat {
  final String name;
  final int count;
  final int value;
  CategoryStat(this.name, this.count, this.value);
}

class BackupRecord {
  final String fileName;
  final int size;
  final String createdAt;
  BackupRecord(this.fileName, this.size, this.createdAt);
}
