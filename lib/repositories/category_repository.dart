import '../core/data_bus.dart';
import '../core/utils.dart';
import '../database/app_database.dart';
import '../models/records.dart';

class CategoryRepository {
  CategoryRepository._();
  static final CategoryRepository I = CategoryRepository._();

  Future<List<Category>> list() async {
    final db = await AppDatabase.instance;
    final rows = await db.rawQuery('''
SELECT c.id, c.name,
  (SELECT COUNT(*) FROM products p WHERE p.category_id = c.id AND p.is_archived = 0) AS cnt
FROM categories c ORDER BY c.name COLLATE NOCASE''');
    return rows.map(Category.fromMap).toList();
  }

  Future<int> add(String name) async {
    final n = name.trim();
    if (n.isEmpty) throw AppException('Kategoriya nomini kiriting.');
    final db = await AppDatabase.instance;
    final ex = await db.rawQuery(
        'SELECT 1 FROM categories WHERE LOWER(name) = LOWER(?) LIMIT 1', [n]);
    if (ex.isNotEmpty) throw AppException('Bunday kategoriya mavjud.');
    final id = await db.insert('categories', {'name': n, 'created_at': nowIso()});
    DataBus.I.changed();
    return id;
  }

  Future<void> rename(int id, String name) async {
    final n = name.trim();
    if (n.isEmpty) throw AppException('Kategoriya nomini kiriting.');
    final db = await AppDatabase.instance;
    final ex = await db.rawQuery(
        'SELECT 1 FROM categories WHERE LOWER(name) = LOWER(?) AND id != ? LIMIT 1',
        [n, id]);
    if (ex.isNotEmpty) throw AppException('Bunday kategoriya mavjud.');
    await db.update('categories', {'name': n}, where: 'id = ?', whereArgs: [id]);
    DataBus.I.changed();
  }

  /// Kategoriya o'chirilsa, undagi mahsulotlar "kategoriyasiz" bo'lib qoladi.
  Future<void> delete(int id) async {
    final db = await AppDatabase.instance;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
    DataBus.I.changed();
  }
}
