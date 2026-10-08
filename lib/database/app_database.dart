import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Barcha jadvallar shu yerda yaratiladi. Kelajakda yangi jadvallar
/// (sales, customers, units...) `_migrations` ga qo'shiladi.
class AppDatabase {
  AppDatabase._();

  static Future<Database>? _future;
  static Future<Database> get instance => _future ??= _open();

  static const int dbVersion = 1;

  static Future<Database> _open() async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    final path = p.join(dir.path, 'tovar_boshqaruv.db');
    return openDatabase(
      path,
      version: dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) => _create(db),
      onUpgrade: (db, oldV, newV) async {
        for (var v = oldV + 1; v <= newV; v++) {
          final m = _migrations[v];
          if (m != null) {
            for (final sql in m) {
              await db.execute(sql);
            }
          }
        }
      },
    );
  }

  /// Kelajak versiyalar uchun: { 2: ['ALTER TABLE ...'], 3: [...] }
  static final Map<int, List<String>> _migrations = {};

  static Future<void> _create(Database db) async {
    await db.execute('''
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL
)''');
    await db.execute('''
CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  search_key TEXT NOT NULL,
  category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
  product_code TEXT NOT NULL UNIQUE,
  qr_code TEXT NOT NULL UNIQUE,
  barcode TEXT UNIQUE,
  image_path TEXT,
  purchase_price INTEGER NOT NULL DEFAULT 0 CHECK (purchase_price >= 0),
  retail_price INTEGER NOT NULL DEFAULT 0 CHECK (retail_price >= 0),
  wholesale_price INTEGER NOT NULL DEFAULT 0 CHECK (wholesale_price >= 0),
  quantity INTEGER NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  minimum_quantity INTEGER NOT NULL DEFAULT 0 CHECK (minimum_quantity >= 0),
  note TEXT,
  is_archived INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)''');
    await db.execute('''
CREATE TABLE stock_movements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  old_quantity INTEGER NOT NULL,
  new_quantity INTEGER NOT NULL,
  purchase_price INTEGER,
  reason TEXT,
  note TEXT,
  created_at TEXT NOT NULL
)''');
    await db.execute('''
CREATE TABLE price_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  old_purchase_price INTEGER,
  new_purchase_price INTEGER NOT NULL,
  old_retail_price INTEGER,
  new_retail_price INTEGER NOT NULL,
  old_wholesale_price INTEGER,
  new_wholesale_price INTEGER NOT NULL,
  created_at TEXT NOT NULL
)''');
    await db.execute('''
CREATE TABLE product_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER,
  product_name TEXT,
  action TEXT NOT NULL,
  details TEXT,
  created_at TEXT NOT NULL
)''');
    await db.execute('''
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT
)''');
    await db.execute('''
CREATE TABLE backups (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  file_name TEXT NOT NULL,
  size INTEGER NOT NULL,
  created_at TEXT NOT NULL
)''');
    await db.execute('CREATE INDEX idx_products_search ON products(search_key)');
    await db.execute('CREATE INDEX idx_products_cat ON products(category_id)');
    await db.execute('CREATE INDEX idx_products_arch ON products(is_archived)');
    await db.execute('CREATE INDEX idx_moves_product ON stock_movements(product_id)');
    await db.execute('CREATE INDEX idx_price_product ON price_history(product_id)');
    await db.execute('CREATE INDEX idx_hist_created ON product_history(created_at)');
  }
}
