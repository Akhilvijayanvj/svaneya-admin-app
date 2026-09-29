import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../main.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('categories')
          .select('*')
          .order('created_at', ascending: false);
      setState(() => _categories = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCategory(String id) async {
    try {
      await supabase.from('categories').delete().eq('id', id);
      _fetchCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting category: $e')));
    }
  }

  void _showAddCategorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const _AddCategoryForm(),
      ),
    ).then((_) => _fetchCategories());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategorySheet,
        backgroundColor: const Color(0xFF1E293B),
        child: const Icon(LucideIcons.plus, color: Color(0xFFBFFF07)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _categories.isEmpty
              ? const Center(child: Text("No categories found."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: cat['image_url'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  cat['image_url'],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(LucideIcons.imageOff, color: Colors.grey)),
                                ),
                              )
                            : Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)), child: const Icon(LucideIcons.image, color: Colors.grey)),
                        title: Text(cat['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        trailing: IconButton(
                          icon: const Icon(LucideIcons.trash2, color: Colors.red),
                          onPressed: () => _deleteCategory(cat['id']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _AddCategoryForm extends StatefulWidget {
  const _AddCategoryForm();

  @override
  State<_AddCategoryForm> createState() => _AddCategoryFormState();
}

class _AddCategoryFormState extends State<_AddCategoryForm> {
  final _nameController = TextEditingController();
  File? _selectedImage;
  bool _isSaving = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _saveCategory() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a category name')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        final fileName = 'category_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('product-images').upload(fileName, _selectedImage!);
        imageUrl = supabase.storage.from('product-images').getPublicUrl(fileName);
      }

      await supabase.from('categories').insert({
        'name': _nameController.text.trim(),
        'image_url': imageUrl,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving category: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Add New Category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          // Image Picker
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              ),
              child: _selectedImage != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_selectedImage!, fit: BoxFit.cover))
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.imagePlus, color: Colors.grey, size: 32),
                        SizedBox(height: 8),
                        Text('Tap to upload image', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Name Input
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Category Name',
              labelStyle: TextStyle(color: Colors.grey.shade600),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 32),

          // Save Button
          ElevatedButton(
            onPressed: _isSaving ? null : _saveCategory,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: const Color(0xFFBFFF07),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFFBFFF07), strokeWidth: 2))
                : const Text('Save Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
