import 'package:flutter/material.dart';
import '../main.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'order_detail.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _isLoading = true;
  List<dynamic> _orders = [];
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final res = await supabase.from('orders').select().order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _orders = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _orders.where((o) {
      if (_filter == 'All') return true;
      return (o['status'] ?? '').toString().toLowerCase() == _filter.toLowerCase();
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
            const Text('Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black)),
            Text('Manage and track your orders', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black), onPressed: () {}),
          const SizedBox(width: 8)
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by order ID, customer...',
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
                _buildFilterChip('All'),
                _buildFilterChip('Pending'),
                _buildFilterChip('Paid'),
                _buildFilterChip('Shipped'),
                _buildFilterChip('Delivered'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchOrders,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final o = filtered[index];
                      final date = DateTime.parse(o['created_at']).toLocal();
                      final shortId = o['id'].toString().substring(0, 8).toUpperCase();
                      final status = (o['status'] ?? 'pending').toString().toUpperCase();
                      
                      Color statusBg = Colors.grey.shade100;
                      Color statusText = Colors.grey.shade700;
                      if (status == 'PAID') { statusBg = Colors.green.shade50; statusText = Colors.green; }
                      else if (status == 'SHIPPED') { statusBg = Colors.blue.shade50; statusText = Colors.blue; }
                      else if (status == 'DELIVERED') { statusBg = Colors.purple.shade50; statusText = Colors.purple; }
                      else if (status == 'CANCELLED') { statusBg = Colors.red.shade50; statusText = Colors.red; }

                      return GestureDetector(
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o['id'])));
                          _fetchOrders();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('#$shortId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(o['customer_name'] ?? 'Unknown', style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(DateFormat('M/d/yyyy').format(date), style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                                        child: Text(status, style: TextStyle(color: statusText, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text('₹${o['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
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
