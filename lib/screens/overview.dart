import 'package:flutter/material.dart';
import '../main.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'add_product.dart';

class OverviewScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const OverviewScreen({super.key, this.onNavigate});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  bool _isLoading = true;
  double _totalRevenue = 0;
  int _totalOrders = 0;
  int _totalProducts = 0;
  
  List<dynamic> _recentOrders = [];
  List<dynamic> _alerts = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final ordersRes = await supabase.from('orders').select().order('created_at', ascending: false);
      final productsRes = await supabase.from('products').select('id');
      final alertsRes = await supabase.from('admin_notifications').select().eq('is_read', false).order('created_at', ascending: false);
      
      double revenue = 0;
      for (var o in ordersRes) {
        revenue += (o['total_amount'] as num).toDouble();
      }
      
      if (mounted) {
        setState(() {
          _totalRevenue = revenue;
          _totalOrders = ordersRes.length;
          _totalProducts = productsRes.length;
          _recentOrders = ordersRes.take(3).toList();
          _alerts = alertsRes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _dismissAlert(String id) async {
    await supabase.from('admin_notifications').update({'is_read': true}).eq('id', id);
    _fetchDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: const Text('Store Dashboard'), centerTitle: true, surfaceTintColor: Colors.transparent),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchDashboardData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Metrics
                _buildStatCard('Total Revenue', '₹${_totalRevenue.toStringAsFixed(2)}', LucideIcons.wallet, Colors.green),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Orders', '$_totalOrders', LucideIcons.shoppingBag, Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Products', '$_totalProducts', LucideIcons.package, Colors.orange)),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Store Management Quick Actions
                const Text('Store Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                  children: [
                    _buildQuickAction('Add Product', LucideIcons.plusCircle, Colors.pink, () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
                      _fetchDashboardData();
                    }),
                    _buildQuickAction('All Products', LucideIcons.package, Colors.indigo, () => widget.onNavigate?.call(1)),
                    _buildQuickAction('All Orders', LucideIcons.shoppingCart, Colors.blue, () => widget.onNavigate?.call(2)),
                    _buildQuickAction('Settings', LucideIcons.settings, Colors.grey.shade800, () => widget.onNavigate?.call(3)),
                  ],
                ),
                const SizedBox(height: 24),

                // Customer Alerts
                if (_alerts.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.circle, size: 12, color: Colors.orange.shade600),
                            const SizedBox(width: 8),
                            Text('Customer Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${_alerts.length} recent changes require your attention', style: TextStyle(color: Colors.orange.shade700, fontSize: 13)),
                        const SizedBox(height: 12),
                        ..._alerts.map((a) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade100)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(a['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                                  InkWell(
                                    onTap: () => _dismissAlert(a['id']),
                                    child: Text('Dismiss', style: TextStyle(color: Colors.orange.shade700, fontSize: 12, decoration: TextDecoration.underline)),
                                  )
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(a['message'] ?? '', style: TextStyle(color: Colors.orange.shade800, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(DateFormat('MMM d, yyyy - h:mm a').format(DateTime.parse(a['created_at']).toLocal()), style: TextStyle(color: Colors.orange.shade400, fontSize: 11)),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Recent Orders
                const Text('Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (_recentOrders.isEmpty)
                  const Text('No recent orders')
                else
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentOrders.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final o = _recentOrders[index];
                        return ListTile(
                          title: Text(o['customer_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('₹${o['total_amount']} • ${o['status'].toString().toUpperCase()}', style: const TextStyle(fontSize: 12)),
                          trailing: Text(DateFormat('MMM d').format(DateTime.parse(o['created_at']).toLocal()), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        );
                      }
                    ),
                  )
              ],
            ),
          ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          ],
        ),
      ),
    );
  }
}
