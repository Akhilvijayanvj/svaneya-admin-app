import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../main.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _mrpCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _badgeCtrl = TextEditingController();

  final List<XFile> _selectedImages = [];
  final _imagePicker = ImagePicker();

  bool _isBestSeller = false;
  bool _isNewArrival = false;
  bool _isSpecialEdition = false;
  bool _isArchived = false;
  bool _isLoading = false;
  bool _isUploading = false;

  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await supabase.from('categories').select('id, name').order('name');
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (_) {}
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      _showSnack('Maximum 5 images allowed');
      return;
    }
    final picked = await _imagePicker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        final remaining = 5 - _selectedImages.length;
        _selectedImages.addAll(picked.take(remaining));
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<List<String>> _uploadImages() async {
    final urls = <String>[];
    for (final xfile in _selectedImages) {
      final file = File(xfile.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${xfile.name}';
      await supabase.storage.from('product-images').upload(fileName, file);
      final url = supabase.storage.from('product-images').getPublicUrl(fileName);
      urls.add(url);
    }
    return urls;
  }

  Future<void> _saveProduct() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnack('Please enter a product name');
      return;
    }
    if (_priceCtrl.text.trim().isEmpty) {
      _showSnack('Please enter the selling price');
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        setState(() => _isUploading = true);
        imageUrls = await _uploadImages();
        setState(() => _isUploading = false);
      }

      await supabase.from('products').insert({
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': double.parse(_priceCtrl.text.trim()),
        'mrp': _mrpCtrl.text.trim().isNotEmpty ? double.parse(_mrpCtrl.text.trim()) : null,
        'stock': int.tryParse(_stockCtrl.text.trim()) ?? 0,
        'category': _selectedCategory,
        'images': imageUrls,
        'is_best_seller': _isBestSeller,
        'is_new_arrival': _isNewArrival,
        'is_special_edition': _isSpecialEdition,
        'is_archived': _isArchived,
        'badge_text': _badgeCtrl.text.trim().isNotEmpty ? _badgeCtrl.text.trim() : null,
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _isUploading = false; });
        _showSnack('Error: $e');
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _mrpCtrl.dispose();
    _stockCtrl.dispose();
    _badgeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
            Text('Add a new product to your store', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Product Name ──────────────────────────────────────
            _label('Product Name'),
            _field(_nameCtrl, 'e.g. Premium T-Shirt'),
            const SizedBox(height: 20),

            // ── Description ───────────────────────────────────────
            _label('Description'),
            _field(_descCtrl, 'Write product description...', maxLines: 4),
            const SizedBox(height: 20),

            // ── Price Row ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Selling Price (₹)'),
                      _field(_priceCtrl, 'e.g. 999', isNumber: true),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('MRP (₹)'),
                      _field(_mrpCtrl, 'e.g. 1,999', isNumber: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Stock ─────────────────────────────────────────────
            _label('Stock Quantity'),
            _field(_stockCtrl, 'e.g. 25', isNumber: true),
            const SizedBox(height: 20),

            // ── Category ──────────────────────────────────────────
            _label('Category'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: Text('Select category', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                  value: _selectedCategory,
                  onChanged: (val) => setState(() => _selectedCategory = val),
                  items: _categories.map((c) => DropdownMenuItem<String>(
                    value: c['name'],
                    child: Text(c['name'], style: const TextStyle(fontSize: 14)),
                  )).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Product Images ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _label('Product Images', noBottom: true),
                Text('${_selectedImages.length}/5', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),

            // Image preview strip
            if (_selectedImages.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(_selectedImages[i].path), width: 100, height: 100, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 4, right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(i),
                            child: Container(
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.close, color: Colors.white, size: 14),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Add Image button
            if (_selectedImages.length < 5)
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.imagePlus, size: 28, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      const Text('Tap to choose images', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('Select up to ${5 - _selectedImages.length} more photo(s) from gallery', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 28),

            // ── Product Flags ─────────────────────────────────────
            _label('Product Labels', noBottom: true),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _switchTile(
                    LucideIcons.trendingUp, 'Best Seller',
                    'Show in Best Sellers section', Colors.orange,
                    _isBestSeller, (v) => setState(() => _isBestSeller = v),
                    divider: true,
                  ),
                  _switchTile(
                    LucideIcons.sparkles, 'New Arrival',
                    'Show in New Arrivals section', Colors.blue,
                    _isNewArrival, (v) => setState(() => _isNewArrival = v),
                    divider: true,
                  ),
                  _switchTile(
                    LucideIcons.star, 'Special Edition',
                    'Show in Special Editions section', Colors.purple,
                    _isSpecialEdition, (v) => setState(() => _isSpecialEdition = v),
                    divider: true,
                  ),
                  _switchTile(
                    LucideIcons.eyeOff, 'Archive / Hide Product',
                    'Will not appear on storefront', Colors.red,
                    _isArchived, (v) => setState(() => _isArchived = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Badge Text ────────────────────────────────────────
            Row(
              children: [
                const Icon(LucideIcons.tag, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                _label('Product Badge', noBottom: true),
              ],
            ),
            const SizedBox(height: 4),
            Text('This text will appear in a bubble over the product image', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 10),
            _field(_badgeCtrl, 'e.g. HIGH DEMAND'),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBFFF07),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                elevation: 0,
              ),
              child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5)),
                      const SizedBox(width: 12),
                      Text(_isUploading ? 'Uploading images...' : 'Saving...', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  )
                : const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, {bool noBottom = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: noBottom ? 0 : 8, left: 2),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, {int maxLines = 1, bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E293B), width: 1.5)),
      ),
    );
  }

  Widget _switchTile(IconData icon, String title, String subtitle, MaterialColor color, bool value, ValueChanged<bool> onChanged, {bool divider = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFFBFFF07),
                activeTrackColor: const Color(0xFF1E293B),
                inactiveTrackColor: Colors.grey.shade200,
                inactiveThumbColor: Colors.grey.shade400,
              ),
            ],
          ),
        ),
        if (divider) Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
      ],
    );
  }
}
