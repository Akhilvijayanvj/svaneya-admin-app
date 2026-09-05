import 'package:flutter/material.dart';
import '../main.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  bool _isLoading = true;
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final res = await supabase.from('products').select().order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _products = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () {
              // TODO: Add Product Screen
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add product coming soon')));
            },
          )
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchProducts,
            child: ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final p = _products[index];
                final stock = p['stock'] ?? 0;
                return ListTile(
                  leading: p['images'] != null && (p['images'] as List).isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(p['images'][0], width: 48, height: 48, fit: BoxFit.cover),
                        )
                      : Container(width: 48, height: 48, color: Colors.grey.shade200, child: const Icon(Icons.image)),
                  title: Text(p['name'], maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('₹${p['price']} • Stock: $stock'),
                  trailing: stock < 5 ? const Icon(Icons.warning, color: Colors.orange, size: 20) : null,
                  onTap: () {},
                );
              },
            ),
          ),
    );
  }
}
