import 'package:flutter/material.dart';
import '../main.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  bool _isLoading = true;
  double _totalRevenue = 0;
  int _totalOrders = 0;
  int _totalProducts = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final ordersRes = await supabase.from('orders').select('total_amount');
      final productsRes = await supabase.from('products').select('id', const FetchOptions(count: CountOption.exact));
      
      double revenue = 0;
      for (var o in ordersRes) {
        revenue += (o['total_amount'] as num).toDouble();
      }
      
      if (mounted) {
        setState(() {
          _totalRevenue = revenue;
          _totalOrders = ordersRes.length;
          _totalProducts = productsRes.length;
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
      appBar: AppBar(title: const Text('Store Overview'), centerTitle: true),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchStats,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatCard('Total Revenue', '₹${_totalRevenue.toStringAsFixed(2)}', Icons.currency_rupee, Colors.green),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Orders', '$_totalOrders', Icons.shopping_bag, Colors.blue)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Products', '$_totalProducts', Icons.inventory_2, Colors.orange)),
                  ],
                )
              ],
            ),
          ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
