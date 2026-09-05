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
  bool _isActive = true;
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
        'images': _imageCtrl.text.isNotEmpty ? [_imageCtrl.text] : [],
        'is_archived': !_isActive,
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
            Text('Add a new product to your store', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black), onPressed: () {}),
          const SizedBox(width: 8)
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Upload Area (Dotted Border)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid), // Flutter doesn't have dashed borders out of box, simulate with dotted decoration package if needed, using solid light grey for now
              ),
              child: Column(
                children: [
                  const Icon(LucideIcons.image, size: 40, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Add Product Images', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Tap to upload or drag and drop\nAdd up to 5 images', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Image URL alternative for now
            _buildLabel('Image URL'),
            _buildTextField(controller: _imageCtrl, hint: 'https://...'),
            const SizedBox(height: 16),

            _buildLabel('Product Name'),
            _buildTextField(controller: _nameCtrl, hint: 'e.g. Premium T-Shirt'),
            const SizedBox(height: 16),

            _buildLabel('Description'),
            _buildTextField(controller: _descCtrl, hint: 'Write product description...', maxLines: 4),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Price (₹)'),
                      _buildTextField(controller: _priceCtrl, hint: 'e.g. 999', isNumber: true),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Stock Quantity'),
                      _buildTextField(controller: _stockCtrl, hint: 'e.g. 10', isNumber: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildLabel('Category'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select category', style: TextStyle(color: Colors.grey)),
                  Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Active Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Product will be visible in your store', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
                Switch(
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                  activeColor: const Color(0xFFBFFF07),
                  activeTrackColor: const Color(0xFFBFFF07).withOpacity(0.5),
                )
              ],
            ),
            const SizedBox(height: 100), // Space for bottom button
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
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
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, int maxLines = 1, bool isNumber = false}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E293B))),
      ),
    );
  }
}
