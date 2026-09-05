import 'package:flutter/material.dart';
import '../main.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
  int _pendingOrders = 0;
  int _totalProducts = 0;
  int _alertCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final ordersRes = await supabase.from('orders').select();
      final productsRes = await supabase.from('products').select('id');
      final alertsRes = await supabase.from('admin_notifications').select('id', const FetchOptions(count: CountOption.exact)).eq('is_read', false);
      
      double revenue = 0;
      int pending = 0;
      for (var o in ordersRes) {
        revenue += (o['total_amount'] as num).toDouble();
        if (o['status'] == 'pending') pending++;
      }
      
      if (mounted) {
        setState(() {
          _totalRevenue = revenue;
          _totalOrders = ordersRes.length;
          _pendingOrders = pending;
          _totalProducts = productsRes.length;
          _alertCount = alertsRes.count ?? 0;
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchDashboardData,
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Top Header
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=Admin&background=1E293B&color=BFFF07'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Hi, Admin 👋', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Svaneya Store', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
                        child: const Icon(LucideIcons.bell, size: 20),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Dark Revenue Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Today's Revenue", style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                            const Icon(LucideIcons.barChart2, color: Color(0xFFBFFF07), size: 24),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('₹${_totalRevenue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(LucideIcons.arrowUpRight, color: Color(0xFFBFFF07), size: 16),
                            const SizedBox(width: 4),
                            Text('18% vs yesterday', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
                                  _fetchDashboardData();
                                },
                                icon: const Icon(LucideIcons.plus, size: 18),
                                label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFBFFF07),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => widget.onNavigate?.call(2),
                                icon: const Icon(LucideIcons.shoppingBag, size: 18),
                                label: const Text('View Orders', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(color: Colors.grey.shade700),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Metrics Grid
                  Row(
                    children: [
                      Expanded(child: _buildMetricBox('Total Orders', '$_totalOrders', 'lifetime orders', LucideIcons.shoppingCart, Colors.blue.shade50, Colors.blue)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildMetricBox('Pending Orders', '$_pendingOrders', 'Awaiting fulfillment', LucideIcons.clock, Colors.orange.shade50, Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildMetricBox('Total Products', '$_totalProducts', 'Active in store', LucideIcons.package, Colors.purple.shade50, Colors.purple)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => widget.onNavigate?.call(3),
                          child: _buildMetricBox('Customer Alerts', '$_alertCount', 'Need attention', LucideIcons.alertTriangle, Colors.red.shade50, Colors.red, isAlert: _alertCount > 0)
                        )
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Quick Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('See All ➔', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickActionBtn('Products', LucideIcons.box, () => widget.onNavigate?.call(1)),
                      _buildQuickActionBtn('Orders', LucideIcons.shoppingBag, () => widget.onNavigate?.call(2)),
                      _buildQuickActionBtn('Coupons', LucideIcons.ticket, () => widget.onNavigate?.call(4)),
                      _buildQuickActionBtn('Reports', LucideIcons.barChart, () {}),
                    ],
                  )
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildMetricBox(String title, String value, String subtitle, IconData icon, Color bg, Color iconColor, {bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isAlert ? Colors.red : Colors.black)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: isAlert ? Colors.red.shade300 : Colors.grey.shade500, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildQuickActionBtn(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.black, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
