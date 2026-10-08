import 'dart:io';
import 'package:flutter/material.dart';

bool get isMobile => Platform.isAndroid || Platform.isIOS;

class AppException implements Exception {
  final String message;
  AppException(this.message);
  @override
  String toString() => message;
}

String formatInt(int v) {
  final neg = v < 0;
  final s = v.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return '${neg ? '-' : ''}$b';
}

String formatMoney(int v) => "${formatInt(v)} so'm";

String formatDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  String t(int n) => n.toString().padLeft(2, '0');
  return '${t(d.day)}.${t(d.month)}.${d.year} ${t(d.hour)}:${t(d.minute)}';
}

String nowIso() => DateTime.now().toIso8601String();

/// Faqat raqamlardan iborat (bo'sh joy ruxsat) musbat son. Noto'g'ri bo'lsa null.
int? parseNonNegative(String s) {
  final t = s.trim();
  if (!RegExp(r'^\d+( \d+)*$').hasMatch(t)) return null;
  return int.tryParse(t.replaceAll(' ', ''));
}

const String kGenericError = "Xatolik yuz berdi. Qayta urinib ko'ring.";

void showMsg(BuildContext context, String text, {bool error = false}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(text),
    behavior: SnackBarBehavior.floating,
    backgroundColor: error ? Theme.of(context).colorScheme.error : null,
  ));
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Ha',
  bool danger = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish')),
        FilledButton(
          style: danger
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error)
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return r ?? false;
}

Future<String?> promptText(BuildContext context,
    {required String title, String initial = '', String hint = ''}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _PromptDialog(title: title, initial: initial, hint: hint),
  );
}

class _PromptDialog extends StatefulWidget {
  final String title;
  final String initial;
  final String hint;
  const _PromptDialog(
      {required this.title, required this.initial, required this.hint});
  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  late final TextEditingController _c =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _c,
        autofocus: true,
        decoration: InputDecoration(
          hintText: widget.hint,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish')),
        FilledButton(
            onPressed: () => Navigator.pop(context, _c.text.trim()),
            child: const Text('Saqlash')),
      ],
    );
  }
}
