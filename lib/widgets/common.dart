import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/image_service.dart';
import '../theme/app_theme.dart';

InputDecoration inputDec(String label, {String? hint, Widget? suffix, String? prefixText}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix,
      prefixText: prefixText,
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

class Constrained extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const Constrained({super.key, required this.child, this.maxWidth = 1100});
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}

class ProductImage extends StatelessWidget {
  final String? path;
  final double size;
  final double radius;
  const ProductImage({super.key, this.path, this.size = 64, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: size,
      height: size,
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.inventory_2_outlined, size: size * 0.45, color: cs.onSurfaceVariant),
    );
    final f = ImageService.file(path);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: f == null
          ? placeholder
          : Image.file(
              f,
              width: size,
              height: size,
              fit: BoxFit.cover,
              cacheWidth: (size * 2).round(),
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final StockStatus status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    late Color c;
    late Color bg;
    late String t;
    switch (status) {
      case StockStatus.ok:
        c = AppTheme.okColor;
        bg = AppTheme.okBg;
        t = '🟢 Mavjud';
        break;
      case StockStatus.low:
        c = AppTheme.lowColor;
        bg = AppTheme.lowBg;
        t = '🟡 Kam qolgan';
        break;
      case StockStatus.out:
        c = AppTheme.outColor;
        bg = AppTheme.outBg;
        t = '🔴 Tugagan';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(t, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: c)),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final VoidCallback? onTap;
  const StatCard({super.key, required this.icon, required this.label, required this.value, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.primary;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
            ),
          ]),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// Ekran kengligiga qarab 2 yoki 3 ustunli kartalar.
class StatGrid extends StatelessWidget {
  final List<Widget> children;
  const StatGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 900 ? 4 : (c.maxWidth >= 560 ? 3 : 2);
      const gap = 10.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final ch in children) SizedBox(width: w, child: ch)],
      );
    });
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
        child: Row(children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
          if (trailing != null) trailing!,
        ]),
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.text, this.action});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 56, color: cs.outline),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ]),
      ),
    );
  }
}

class DateField extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  const DateField({super.key, required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    String t(int n) => n.toString().padLeft(2, '0');
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (d != null) {
          final n = DateTime.now();
          onChanged(DateTime(d.year, d.month, d.day, n.hour, n.minute, n.second));
        }
      },
      child: InputDecorator(
        decoration: inputDec('Sana', suffix: const Icon(Icons.calendar_today_outlined, size: 18)),
        child: Text('${t(date.day)}.${t(date.month)}.${date.year}'),
      ),
    );
  }
}
