import 'package:flutter/material.dart';
import '../main.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveProduct() async {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      await supabase.from('products').insert({
        'name': _nameCtrl.text,
        'description': _descCtrl.text,
        'price': double.parse(_priceCtrl.text),
        'stock': int.tryParse(_stockCtrl.text) ?? 0,
        'category_id': _catCtrl.text.isEmpty ? null : _catCtrl.text,
        'images': _imageCtrl.text.isNotEmpty ? [_imageCtrl.text] : [],
      });
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        actions: [
          IconButton(icon: const Icon(LucideIcons.save), onPressed: _isLoading ? null : _saveProduct),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(
              controller: _priceCtrl, 
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (₹)', border: OutlineInputBorder(), prefixText: '₹ '),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _stockCtrl, 
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stock Quantity', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _catCtrl, 
              decoration: const InputDecoration(labelText: 'Category ID (Optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _imageCtrl, 
              decoration: const InputDecoration(labelText: 'Image URL', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl, 
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Description (Supports HTML)', 
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
