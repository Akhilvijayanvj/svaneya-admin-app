import 'package:flutter/material.dart';
import '../main.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'add_product.dart';
import 'categories.dart';
import 'notifications.dart';
import 'promo_codes.dart';
import 'mobile_banner.dart';
import 'web_banner.dart';

class OverviewScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  final Function(String)? onNavigateToOrders;
  const OverviewScreen({super.key, this.onNavigate, this.onNavigateToOrders});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  bool _isLoading = true;
  double _todayRevenue = 0;
  double _revenueGrowth = 0;
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
      final alertsRes = await supabase.from('admin_notifications').select('id').eq('is_read', false);
      
      double todayRev = 0;
      double yesterdayRev = 0;
      int pending = 0;

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final yesterdayStart = todayStart.subtract(const Duration(days: 1));

      for (var o in ordersRes) {
        if (o['status'] == 'pending') pending++;
        
        final createdAtStr = o['created_at'];
        if (createdAtStr != null) {
          final createdAt = DateTime.parse(createdAtStr).toLocal();
          final amount = (o['total_amount'] as num).toDouble();
          
          if (createdAt.isAfter(todayStart) || createdAt.isAtSameMomentAs(todayStart)) {
            todayRev += amount;
          } else if (createdAt.isAfter(yesterdayStart) && createdAt.isBefore(todayStart)) {
            yesterdayRev += amount;
          }
        }
      }
      
      double growth = 0;
      if (yesterdayRev > 0) {
        growth = ((todayRev - yesterdayRev) / yesterdayRev) * 100;
      } else if (todayRev > 0) {
        growth = 100;
      }
      
      if (mounted) {
        setState(() {
          _todayRevenue = todayRev;
          _revenueGrowth = growth;
          _totalOrders = ordersRes.length;
          _pendingOrders = pending;
          _totalProducts = productsRes.length;
          _alertCount = alertsRes.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Colors.transparent, // Let dashboard scaffold handle background
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
                            Text('Hi, Admin 👋', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Svaneya Store', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (themeNotifier.value == ThemeMode.light) {
                            themeNotifier.value = ThemeMode.dark;
                          } else {
                            themeNotifier.value = ThemeMode.light;
                          }
                        },
                        child: ValueListenableBuilder<ThemeMode>(
                          valueListenable: themeNotifier,
                          builder: (context, mode, _) {
                            final isDark = mode == ThemeMode.dark;
                            return Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle, 
                                border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)
                              ),
                              child: Icon(isDark ? LucideIcons.sun : LucideIcons.moon, size: 20),
                            );
                          }
                        ),
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
                        Text('₹${_todayRevenue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _revenueGrowth >= 0 ? LucideIcons.arrowUpRight : LucideIcons.arrowDownRight, 
                              color: _revenueGrowth >= 0 ? const Color(0xFFBFFF07) : Colors.redAccent, 
                              size: 16
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_revenueGrowth.abs().toStringAsFixed(1)}% vs yesterday', 
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)
                            ),
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
                      Expanded(
                        child: GestureDetector(
                          onTap: () => widget.onNavigateToOrders?.call('All') ?? widget.onNavigate?.call(2),
                          child: _buildMetricBox('Total Orders', '$_totalOrders', 'lifetime orders', LucideIcons.shoppingCart, Colors.blue.shade50, Colors.blue)
                        )
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => widget.onNavigateToOrders?.call('Pending') ?? widget.onNavigate?.call(2),
                          child: _buildMetricBox('Pending Orders', '$_pendingOrders', 'Awaiting fulfillment', LucideIcons.clock, Colors.orange.shade50, Colors.orange)
                        )
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => widget.onNavigate?.call(1),
                          child: _buildMetricBox('Total Products', '$_totalProducts', 'Active in store', LucideIcons.package, Colors.purple.shade50, Colors.purple)
                        )
                      ),
                      const SizedBox(width: 8),
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
                      Text('Quick Actions', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('See All ➔', style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final spacing = 8.0;
                      // Subtract spacing for 3 gaps, then divide by 4 exactly
                      final itemWidth = (constraints.maxWidth - (spacing * 3)) / 4.001; 
                      return Wrap(
                        spacing: spacing,
                        runSpacing: 24,
                        alignment: WrapAlignment.start,
                        children: [
                          SizedBox(width: itemWidth, child: _buildQuickActionBtn('Products', LucideIcons.box, () => widget.onNavigate?.call(1))),
                          SizedBox(width: itemWidth, child: _buildQuickActionBtn('Orders', LucideIcons.shoppingBag, () => widget.onNavigate?.call(2))),
                          SizedBox(width: itemWidth, child: _buildQuickActionBtn('Categories', LucideIcons.listTree, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())))),
                          SizedBox(width: itemWidth, child: _buildQuickActionBtn('Coupons', LucideIcons.ticket, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PromoCodesScreen())))),
                          SizedBox(width: itemWidth, child: _buildQuickActionBtn('Web Banners', LucideIcons.globe, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WebBannerScreen())))),
                          SizedBox(width: itemWidth, child: _buildQuickActionBtn('App Banners', LucideIcons.smartphone, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileBannerScreen())))),
                          SizedBox(width: itemWidth, child: _buildQuickActionBtn('Alerts', LucideIcons.bellRing, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())))),
                        ],
                      );
                    }
                  )
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildMetricBox(String title, String value, String subtitle, IconData icon, Color bg, Color iconColor, {bool isAlert = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)),
              Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: isDark ? bg.withOpacity(0.1) : bg, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isAlert ? Colors.red : (isDark ? Colors.white : Colors.black))),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: isAlert ? Colors.red.shade300 : Colors.grey.shade500, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildQuickActionBtn(String label, IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white, 
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.transparent)
            ),
            child: Icon(icon, color: isDark ? Colors.white : Colors.black, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey.shade300 : Colors.black87,
              fontSize: 12, 
              fontWeight: FontWeight.w500
            )
          ),
        ],
      ),
    );
  }
}
