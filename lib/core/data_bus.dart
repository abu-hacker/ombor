import 'package:flutter/foundation.dart';
import '../models/product.dart';

/// Ma'lumot o'zgarganda barcha ekranlarni yangilash uchun.
class DataBus extends ChangeNotifier {
  DataBus._();
  static final DataBus I = DataBus._();
  void changed() => notifyListeners();
}

/// Asosiy navigatsiya holati (Bottom navigation / Sidebar).
class NavController {
  static final ValueNotifier<int> index = ValueNotifier<int>(0);
  static final ValueNotifier<StockFilter?> filterRequest =
      ValueNotifier<StockFilter?>(null);

  static void go(int i) => index.value = i;

  static void openProducts(StockFilter f) {
    filterRequest.value = f;
    index.value = 1;
  }
}
