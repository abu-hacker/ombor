import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../core/app_settings.dart';
import '../core/utils.dart';
import '../models/product.dart';
import '../models/records.dart';
import '../services/backup_service.dart';
import '../services/file_export.dart';
import '../widgets/common.dart';
import 'categories_screen.dart';
import 'history_screen.dart';
import 'products_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;
  List<BackupRecord> _backups = [];

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    try {
      final b = await BackupService.recent();
      if (mounted) setState(() => _backups = b);
    } catch (_) {}
  }

  Future<void> _createBackup() async {
    setState(() => _busy = true);
    try {
      final bytes = await BackupService.create();
      final name = BackupService.suggestedFileName();
      final ok = await FileExport.saveBytes(fileName: name, bytes: bytes);
      if (ok) {
        await BackupService.record(name, bytes.length);
        await _loadBackups();
        if (mounted) showMsg(context, 'Backup tayyor: $name');
      }
    } on AppException catch (e) {
      if (mounted) showMsg(context, e.message, error: true);
    } catch (_) {
      if (mounted) showMsg(context, kGenericError, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final ok = await confirmDialog(context,
        title: 'Backup tiklash',
        message:
            "DIQQAT! Tiklash joriy qurilmadagi BARCHA ma'lumotlarni (tovarlar, rasmlar, tarix) o'chirib, backup faylidagi ma'lumotlar bilan almashtiradi. Davom etasizmi?",
        confirmText: 'Tiklash',
        danger: true);
    if (!ok) return;
    try {
      final r = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['zip'], withData: true);
      if (r == null || r.files.isEmpty) return;
      final f = r.files.single;
      final bytes = f.bytes ?? (f.path != null ? await File(f.path!).readAsBytes() : null);
      if (bytes == null) throw AppException("Faylni o'qib bo'lmadi.");
      setState(() => _busy = true);
      await BackupService.restore(bytes);
      await AppSettings.I.load();
      await _loadBackups();
      if (mounted) showMsg(context, "Ma'lumotlar muvaffaqiyatli tiklandi.");
    } on AppException catch (e) {
      if (mounted) showMsg(context, e.message, error: true);
    } catch (_) {
      if (mounted) showMsg(context, kGenericError, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 12, color: cs.onSurfaceVariant);
    return Scaffold(
      appBar: AppBar(title: const Text('Sozlamalar')),
      body: Constrained(
        maxWidth: 700,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const SectionTitle("Ko'rinish"),
          AppCard(
            child: ListenableBuilder(
              listenable: AppSettings.I,
              builder: (_, __) => SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('Tizim'), icon: Icon(Icons.brightness_auto)),
                    ButtonSegment(value: ThemeMode.light, label: Text("Yorug'"), icon: Icon(Icons.light_mode)),
                    ButtonSegment(value: ThemeMode.dark, label: Text("Qorong'i"), icon: Icon(Icons.dark_mode)),
                  ],
                  selected: {AppSettings.I.themeMode},
                  onSelectionChanged: (s) => AppSettings.I.setThemeMode(s.first),
                ),
              ),
            ),
          ),
          const SectionTitle("Ma'lumotlar"),
          _nav(Icons.category_outlined, 'Kategoriyalar', 'Qo\'shish, tahrirlash, o\'chirish', () => const CategoriesScreen()),
          const SizedBox(height: 8),
          _nav(Icons.archive_outlined, 'Arxiv', 'Arxivlangan tovarlar va ularni tiklash',
              () => const ProductsScreen(standalone: true, title: 'Arxiv', initialFilter: StockFilter.archived)),
          const SizedBox(height: 8),
          _nav(Icons.history, 'Tarix', "Barcha o'zgarishlar jurnali", () => const HistoryScreen()),
          const SectionTitle('Zaxira nusxa (Backup)'),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                "Backup barcha tovar, rasm, narx, qoldiq, kirim-chiqim, tarix va sozlamalarni bitta faylga saqlaydi. "
                "Boshqa telefon yoki kompyuterda \"Backup tiklash\" orqali ma'lumotlarni ko'chirishingiz mumkin.",
                style: muted,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _createBackup,
                    icon: const Icon(Icons.backup_outlined),
                    label: const Text('Backup yaratish'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _restore,
                    icon: const Icon(Icons.restore),
                    label: const Text('Backup tiklash'),
                  ),
                ),
              ]),
              if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
              if (_backups.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('Oxirgi backuplar:', style: muted),
                for (final b in _backups)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${formatDate(b.createdAt)} · ${(b.size / 1024).round()} KB', style: const TextStyle(fontSize: 13)),
                  ),
              ],
            ]),
          ),
          const SectionTitle('Dastur haqida'),
          AppCard(child: Text("Tovar boshqaruv · 1.0.0\nOffline ishlaydi. Ma'lumotlar faqat shu qurilmada saqlanadi.", style: muted)),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _nav(IconData icon, String title, String sub, Widget Function() page) {
    return AppCard(
      onTap: () => Navigator.push<void>(context, MaterialPageRoute(builder: (_) => page())),
      child: Row(children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(sub, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
        ),
        const Icon(Icons.chevron_right),
      ]),
    );
  }
}
