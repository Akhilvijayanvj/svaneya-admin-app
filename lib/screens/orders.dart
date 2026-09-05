import 'package:flutter/material.dart';
import '../main.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _isLoading = true;
  List<dynamic> _orders = [];

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
    return Scaffold(
      appBar: AppBar(title: const Text('Recent Orders')),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchOrders,
            child: ListView.separated(
              itemCount: _orders.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final o = _orders[index];
                final date = DateTime.parse(o['created_at']).toLocal();
                return ListTile(
                  title: Text(o['customer_name'] ?? 'Unknown Customer', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${DateFormat('MMM d, h:mm a').format(date)}\nID: ${o['id'].toString().substring(0, 8).toUpperCase()}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${o['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: o['status'] == 'paid' ? Colors.green.shade100 : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4)
                        ),
                        child: Text(
                          (o['status'] ?? 'pending').toString().toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: o['status'] == 'paid' ? Colors.green.shade700 : Colors.orange.shade700
                          ),
                        ),
                      )
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () {
                    showDialog(context: context, builder: (_) => AlertDialog(
                      title: const Text('Update Order Status'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(title: const Text('Pending'), onTap: () => _updateStatus(o['id'], 'pending')),
                          ListTile(title: const Text('Paid'), onTap: () => _updateStatus(o['id'], 'paid')),
                          ListTile(title: const Text('Shipped'), onTap: () => _updateStatus(o['id'], 'shipped')),
                          ListTile(title: const Text('Delivered'), onTap: () => _updateStatus(o['id'], 'delivered')),
                        ],
                      ),
                    ));
                  },
                );
              },
            ),
          ),
    );
  }

  Future<void> _updateStatus(dynamic id, String status) async {
    Navigator.pop(context);
    setState(() => _isLoading = true);
    await supabase.from('orders').update({'status': status}).eq('id', id);
    _fetchOrders();
  }
}
