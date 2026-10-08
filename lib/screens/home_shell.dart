import 'package:flutter/material.dart';
import '../core/data_bus.dart';
import 'dashboard_screen.dart';
import 'products_screen.dart';
import 'scanner_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  static const _items = [
    (Icons.home_outlined, Icons.home, 'Bosh'),
    (Icons.inventory_2_outlined, Icons.inventory_2, 'Tovarlar'),
    (Icons.qr_code_scanner, Icons.qr_code_scanner, 'Skaner'),
    (Icons.bar_chart_outlined, Icons.bar_chart, 'Statistika'),
    (Icons.settings_outlined, Icons.settings, 'Sozlamalar'),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NavController.index,
      builder: (context, idx, _) {
        final wide = MediaQuery.of(context).size.width >= 820;
        final body = IndexedStack(
          index: idx,
          children: [
            const DashboardScreen(),
            const ProductsScreen(),
            // Kamera faqat Skaner bo'limi ochiq bo'lganda ishlaydi
            idx == 2 ? const ScannerScreen() : const SizedBox.shrink(),
            const StatsScreen(),
            const SettingsScreen(),
          ],
        );

        if (wide) {
          return Scaffold(
            body: Row(children: [
              NavigationRail(
                extended: true,
                minExtendedWidth: 220,
                selectedIndex: idx,
                onDestinationSelected: NavController.go,
                leading: const Padding(
                  padding: EdgeInsets.fromLTRB(8, 20, 8, 16),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.inventory_2, size: 26),
                    SizedBox(width: 10),
                    Text('Tovar boshqaruv', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ]),
                ),
                destinations: [
                  for (final it in _items)
                    NavigationRailDestination(
                      icon: Icon(it.$1),
                      selectedIcon: Icon(it.$2),
                      label: Text(it.$3 == 'Bosh' ? 'Bosh sahifa' : it.$3),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ]),
          );
        }
        return Scaffold(
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: idx,
            onDestinationSelected: NavController.go,
            destinations: [
              for (final it in _items)
                NavigationDestination(icon: Icon(it.$1), selectedIcon: Icon(it.$2), label: it.$3),
            ],
          ),
        );
      },
    );
  }
}
