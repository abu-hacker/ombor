import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/utils.dart';
import '../models/product.dart';
import '../models/records.dart';
import '../repositories/category_repository.dart';
import '../repositories/product_repository.dart';
import '../services/image_service.dart';
import '../widgets/common.dart';
import '../widgets/scanner_view.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  final String? initialBarcode;
  const ProductFormScreen({super.key, this.product, this.initialBarcode});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _qr = TextEditingController();
  final _barcode = TextEditingController();
  final _purchase = TextEditingController();
  final _retail = TextEditingController();
  final _wholesale = TextEditingController();
  final _qty = TextEditingController();
  final _minQty = TextEditingController();
  final _note = TextEditingController();

  List<Category> _categories = [];
  int? _categoryId;
  String? _image;
  String? _originalImage;
  final Set<String> _newImages = {};
  bool _saving = false;
  bool _saved = false;

  bool get _isEdit => widget.product != null;
  final _digits = [FilteringTextInputFormatter.digitsOnly];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _name.text = p.name;
      _code.text = p.productCode;
      _qr.text = p.qrCode;
      _barcode.text = p.barcode ?? '';
      _purchase.text = p.purchasePrice.toString();
      _retail.text = p.retailPrice.toString();
      _wholesale.text = p.wholesalePrice.toString();
      _qty.text = p.quantity.toString();
      _minQty.text = p.minimumQuantity.toString();
      _note.text = p.note ?? '';
      _categoryId = p.categoryId;
      _image = p.imagePath;
      _originalImage = p.imagePath;
    } else {
      _barcode.text = widget.initialBarcode ?? '';
    }
    _init();
  }

  Future<void> _init() async {
    try {
      final cats = await CategoryRepository.I.list();
      String? code;
      String? qr;
      if (!_isEdit) {
        code = await ProductRepository.I.newProductCode();
        qr = await ProductRepository.I.newQrCode();
      }
      if (!mounted) return;
      setState(() {
        _categories = cats;
        if (code != null) _code.text = code;
        if (qr != null) _qr.text = qr;
      });
    } catch (_) {
      if (mounted) showMsg(context, kGenericError, error: true);
    }
  }

  @override
  void dispose() {
    if (!_saved) {
      for (final n in _newImages) {
        ImageService.delete(n);
      }
    }
    for (final c in [_name, _code, _qr, _barcode, _purchase, _retail, _wholesale, _qty, _minQty, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    var camera = false;
    if (isMobile) {
      final choice = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Kameradan olish'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galereyadan tanlash'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (_image != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text("Rasmni olib tashlash"),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
          ]),
        ),
      );
      if (choice == null) return;
      if (choice == 'remove') {
        _removeImage();
        return;
      }
      camera = choice == 'camera';
    }
    try {
      final name = await ImageService.pick(camera: camera);
      if (name == null) return;
      if (_image != null && _newImages.contains(_image)) {
        await ImageService.delete(_image);
        _newImages.remove(_image);
      }
      _newImages.add(name);
      if (mounted) setState(() => _image = name);
    } on PlatformException catch (e) {
      if (!mounted) return;
      final denied = e.code.contains('denied');
      showMsg(context, denied ? 'Kameradan foydalanish uchun ruxsat bering.' : kGenericError, error: true);
    } on AppException catch (e) {
      if (mounted) showMsg(context, e.message, error: true);
    } catch (_) {
      if (mounted) showMsg(context, kGenericError, error: true);
    }
  }

  void _removeImage() {
    if (_image != null && _newImages.contains(_image)) {
      ImageService.delete(_image);
      _newImages.remove(_image);
    }
    setState(() => _image = null);
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const ScanOncePage()));
    if (code != null && mounted) setState(() => _barcode.text = code);
  }

  Future<void> _addCategory() async {
    final name = await promptText(context, title: 'Yangi kategoriya', hint: 'Kategoriya nomi');
    if (name == null) return;
    try {
      final id = await CategoryRepository.I.add(name);
      final cats = await CategoryRepository.I.list();
      if (mounted) setState(() { _categories = cats; _categoryId = id; });
    } on AppException catch (e) {
      if (mounted) showMsg(context, e.message, error: true);
    } catch (_) {
      if (mounted) showMsg(context, kGenericError, error: true);
    }
  }

  String? _priceValidator(String? v) => parseNonNegative(v ?? '') == null ? 'Narxni tekshiring.' : null;

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    final purchase = parseNonNegative(_purchase.text)!;
    final retail = parseNonNegative(_retail.text)!;
    final wholesale = parseNonNegative(_wholesale.text) ?? retail;
    final qty = parseNonNegative(_qty.text) ?? 0;
    final minQty = parseNonNegative(_minQty.text) ?? 0;
    final old = widget.product;
    final barcode = _barcode.text.trim();
    final p = Product(
      id: old?.id,
      name: _name.text.trim(),
      categoryId: _categoryId,
      productCode: _code.text.trim(),
      qrCode: _qr.text.trim(),
      barcode: barcode.isEmpty ? null : barcode,
      imagePath: _image,
      purchasePrice: purchase,
      retailPrice: retail,
      wholesalePrice: wholesale,
      quantity: qty,
      minimumQuantity: minQty,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      isArchived: old?.isArchived ?? false,
      createdAt: old?.createdAt ?? '',
    );
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await ProductRepository.I.update(p);
      } else {
        await ProductRepository.I.add(p);
      }
      _saved = true;
      for (final n in _newImages) {
        if (n != _image) await ImageService.delete(n);
      }
      if (_originalImage != null && _originalImage != _image) {
        await ImageService.delete(_originalImage);
      }
      if (!mounted) return;
      showMsg(context, _isEdit ? 'Saqlandi.' : "Tovar qo'shildi.");
      Navigator.pop(context, true);
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showMsg(context, e.message, error: true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showMsg(context, kGenericError, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final buy = parseNonNegative(_purchase.text);
    final ret = parseNonNegative(_retail.text);
    final whole = parseNonNegative(_wholesale.text);
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Tovarni tahrirlash' : "Tovar qo'shish")),
      body: Constrained(
        maxWidth: 680,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: ProductImage(path: _image, size: 140, radius: 20),
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(isMobile ? Icons.add_a_photo_outlined : Icons.folder_open),
                      label: Text(_image == null ? "Rasm qo'shish" : "Rasmni almashtirish"),
                    ),
                    if (!isMobile && _image != null)
                      TextButton.icon(onPressed: _removeImage, icon: const Icon(Icons.delete_outline), label: const Text('Olib tashlash')),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: inputDec('Tovar nomi *'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Mahsulot nomini kiriting.' : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _categoryId,
                    isExpanded: true,
                    decoration: inputDec('Kategoriya'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Kategoriyasiz')),
                      for (final c in _categories) DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(onPressed: _addCategory, icon: const Icon(Icons.add), tooltip: "Yangi kategoriya"),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                controller: _code,
                decoration: inputDec('Mahsulot kodi'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Mahsulot kodini kiriting.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qr,
                decoration: inputDec('QR kod (avtomatik)', suffix: IconButton(
                  tooltip: 'Yangi QR kod',
                  icon: const Icon(Icons.autorenew),
                  onPressed: () async {
                    final v = await ProductRepository.I.newQrCode();
                    if (mounted) setState(() => _qr.text = v);
                  },
                )),
                validator: (v) => (v ?? '').trim().isEmpty ? 'QR kodni kiriting.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _barcode,
                decoration: inputDec('Barcode (ixtiyoriy)',
                    suffix: isMobile
                        ? IconButton(tooltip: 'Skanerlash', icon: const Icon(Icons.qr_code_scanner), onPressed: _scanBarcode)
                        : null),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _purchase,
                keyboardType: TextInputType.number,
                inputFormatters: _digits,
                onChanged: (_) => setState(() {}),
                decoration: inputDec('Kelish narxi *', prefixText: "so'm  "),
                validator: _priceValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _retail,
                keyboardType: TextInputType.number,
                inputFormatters: _digits,
                onChanged: (_) => setState(() {}),
                decoration: inputDec('Chakana narxi *', prefixText: "so'm  "),
                validator: _priceValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _wholesale,
                keyboardType: TextInputType.number,
                inputFormatters: _digits,
                onChanged: (_) => setState(() {}),
                decoration: inputDec('Ulgurji narxi', hint: "Bo'sh bo'lsa chakana narx", prefixText: "so'm  "),
              ),
              if (buy != null && ret != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Chakana foyda: ${formatMoney(ret - buy)}'
                    '${whole != null ? '   ·   Ulgurji foyda: ${formatMoney(whole - buy)}' : ''}',
                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _qty,
                    keyboardType: TextInputType.number,
                    inputFormatters: _digits,
                    decoration: inputDec('Qoldiq'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _minQty,
                    keyboardType: TextInputType.number,
                    inputFormatters: _digits,
                    decoration: inputDec('Minimal qoldiq'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(controller: _note, maxLines: 3, decoration: inputDec('Izoh')),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Saqlash')),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
