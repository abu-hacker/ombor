enum StockStatus { ok, low, out }

enum StockFilter { all, ok, low, out, archived }

enum SortKey { newest, name, price, quantity }

int _i(Object? v) => v == null ? 0 : (v as num).toInt();

class Product {
  int? id;
  String name;
  int? categoryId;
  String? categoryName;
  String productCode;
  String qrCode;
  String? barcode;
  String? imagePath;
  int purchasePrice;
  int retailPrice;
  int wholesalePrice;
  int quantity;
  int minimumQuantity;
  String? note;
  bool isArchived;
  String createdAt;
  String updatedAt;

  Product({
    this.id,
    required this.name,
    this.categoryId,
    this.categoryName,
    required this.productCode,
    required this.qrCode,
    this.barcode,
    this.imagePath,
    this.purchasePrice = 0,
    this.retailPrice = 0,
    this.wholesalePrice = 0,
    this.quantity = 0,
    this.minimumQuantity = 0,
    this.note,
    this.isArchived = false,
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory Product.fromMap(Map<String, Object?> m) => Product(
        id: m['id'] as int?,
        name: m['name'] as String,
        categoryId: m['category_id'] as int?,
        categoryName: m['category_name'] as String?,
        productCode: m['product_code'] as String,
        qrCode: m['qr_code'] as String,
        barcode: m['barcode'] as String?,
        imagePath: m['image_path'] as String?,
        purchasePrice: _i(m['purchase_price']),
        retailPrice: _i(m['retail_price']),
        wholesalePrice: _i(m['wholesale_price']),
        quantity: _i(m['quantity']),
        minimumQuantity: _i(m['minimum_quantity']),
        note: m['note'] as String?,
        isArchived: _i(m['is_archived']) == 1,
        createdAt: (m['created_at'] as String?) ?? '',
        updatedAt: (m['updated_at'] as String?) ?? '',
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'search_key': name.toLowerCase(),
        'category_id': categoryId,
        'product_code': productCode,
        'qr_code': qrCode,
        'barcode': barcode,
        'image_path': imagePath,
        'purchase_price': purchasePrice,
        'retail_price': retailPrice,
        'wholesale_price': wholesalePrice,
        'quantity': quantity,
        'minimum_quantity': minimumQuantity,
        'note': note,
        'is_archived': isArchived ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  Product copyWith({
    int? purchasePrice,
    int? retailPrice,
    int? wholesalePrice,
    int? quantity,
  }) =>
      Product(
        id: id,
        name: name,
        categoryId: categoryId,
        categoryName: categoryName,
        productCode: productCode,
        qrCode: qrCode,
        barcode: barcode,
        imagePath: imagePath,
        purchasePrice: purchasePrice ?? this.purchasePrice,
        retailPrice: retailPrice ?? this.retailPrice,
        wholesalePrice: wholesalePrice ?? this.wholesalePrice,
        quantity: quantity ?? this.quantity,
        minimumQuantity: minimumQuantity,
        note: note,
        isArchived: isArchived,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  int get retailProfit => retailPrice - purchasePrice;
  int get wholesaleProfit => wholesalePrice - purchasePrice;
  int get potentialRetailProfit => quantity * retailProfit;
  int get potentialWholesaleProfit => quantity * wholesaleProfit;
  int get stockValue => quantity * purchasePrice;

  StockStatus get status {
    if (quantity <= 0) return StockStatus.out;
    if (quantity <= minimumQuantity) return StockStatus.low;
    return StockStatus.ok;
  }
}
