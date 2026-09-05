import 'package:flutter/material.dart';
import '../main.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'add_product.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  bool _isLoading = true;
  List<dynamic> _products = [];
  String _filter = 'All';

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
    final filtered = _products.where((p) {
      if (_filter == 'All') return true;
      if (_filter == 'Active') return p['is_archived'] != true && (p['stock'] ?? 0) > 0;
      if (_filter == 'Out of Stock') return (p['stock'] ?? 0) <= 0;
      if (_filter == 'Draft') return p['is_archived'] == true;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black)),
            Text('Manage your store products', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black), onPressed: () {}),
          const SizedBox(width: 8)
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
          if (result == true) _fetchProducts();
        },
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: const Icon(LucideIcons.plus, color: Color(0xFFBFFF07)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products, categories...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                suffixIcon: const Icon(LucideIcons.slidersHorizontal, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', _products.length, _filter == 'All'),
                _buildFilterChip('Active', _products.where((p) => p['is_archived'] != true && (p['stock'] ?? 0) > 0).length, _filter == 'Active'),
                _buildFilterChip('Draft', _products.where((p) => p['is_archived'] == true).length, _filter == 'Draft'),
                _buildFilterChip('Out of Stock', _products.where((p) => (p['stock'] ?? 0) <= 0).length, _filter == 'Out of Stock'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final p = filtered[index];
                    final stock = p['stock'] ?? 0;
                    final isOos = stock <= 0;
                    final imgUrl = p['images'] != null && (p['images'] as List).isNotEmpty ? p['images'][0] : null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: imgUrl != null 
                              ? Image.network(imgUrl, width: 60, height: 60, fit: BoxFit.cover)
                              : Container(width: 60, height: 60, color: Colors.grey.shade100, child: const Icon(Icons.image, color: Colors.grey)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text('₹${p['price']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('Stock: $stock', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isOos ? Colors.red.shade50 : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8)
                                ),
                                child: Text(
                                  isOos ? 'Out of Stock' : 'Active',
                                  style: TextStyle(color: isOos ? Colors.red : Colors.green, fontSize: 10, fontWeight: FontWeight.bold)
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(
          children: [
            Text(label),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: isSelected ? const Color(0xFFBFFF07) : Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
              child: Text('$count', style: TextStyle(color: isSelected ? Colors.black : Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        selected: isSelected,
        onSelected: (val) => setState(() => _filter = label),
        selectedColor: const Color(0xFF1E293B),
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300)),
        showCheckmark: false,
      ),
    );
  }
}
