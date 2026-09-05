import 'package:flutter/material.dart';
import '../main.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatefulWidget {
  final dynamic orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _order;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchOrder();
  }

  Future<void> _fetchOrder() async {
    try {
      final oRes = await supabase.from('orders').select().eq('id', widget.orderId).single();
      final iRes = await supabase.from('order_items').select('*, products(name, images)').eq('order_id', widget.orderId);
      if (mounted) {
        setState(() {
          _order = oRes;
          _items = iRes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showStatusDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Update Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            _buildStatusOption('pending'),
            _buildStatusOption('paid'),
            _buildStatusOption('shipped'),
            _buildStatusOption('delivered'),
            _buildStatusOption('cancelled'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(String s) {
    return ListTile(
      title: Text(s.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: () async {
        Navigator.pop(context);
        setState(() => _isLoading = true);
        await supabase.from('orders').update({'status': s}).eq('id', widget.orderId);
        _fetchOrder();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_order == null) return const Scaffold(body: Center(child: Text('Order not found')));

    final shortId = _order!['id'].toString().substring(0, 8).toUpperCase();
    final date = DateTime.parse(_order!['created_at']).toLocal();
    final status = (_order!['status'] ?? 'pending').toString().toUpperCase();
    
    Color statusBg = Colors.grey.shade100;
    Color statusText = Colors.grey.shade700;
    if (status == 'PAID') { statusBg = Colors.green.shade50; statusText = Colors.green; }
    else if (status == 'SHIPPED') { statusBg = Colors.blue.shade50; statusText = Colors.blue; }
    else if (status == 'DELIVERED') { statusBg = Colors.purple.shade50; statusText = Colors.purple; }
    else if (status == 'CANCELLED') { statusBg = Colors.red.shade50; statusText = Colors.red; }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text('Order #$shortId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(status, style: TextStyle(color: statusText, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                Text(DateFormat('M/d/yyyy, h:mm a').format(date), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 24),
            
            // Customer Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: Colors.grey.shade200, child: Text(_order!['customer_name'][0].toUpperCase(), style: const TextStyle(color: Colors.black))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_order!['customer_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(_order!['customer_email'] ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), shape: BoxShape.circle),
                    child: const Icon(Icons.phone, size: 16),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Shipping
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Shipping Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  Text(_order!['customer_name'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(_order!['shipping_address'] ?? 'No address provided', style: TextStyle(color: Colors.grey.shade500, height: 1.4, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Items
            Text('Items (${_items.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final i = _items[index];
                  final p = i['products'];
                  final imgUrl = p != null && p['images'] != null && (p['images'] as List).isNotEmpty ? p['images'][0] : null;
                  
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imgUrl != null 
                            ? Image.network(imgUrl, width: 48, height: 48, fit: BoxFit.cover)
                            : Container(width: 48, height: 48, color: Colors.grey.shade100, child: const Icon(Icons.image, color: Colors.grey)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p != null ? p['name'] : 'Product', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('Qty: ${i['quantity']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text('₹${i['price']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            
            // Summary
            const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Subtotal', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    Text('₹${_order!['total_amount']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ]),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Shipping', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    const Text('₹0', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ]),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('₹${_order!['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 100),
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
              onPressed: _showStatusDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBFFF07),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                elevation: 0,
              ),
              child: const Text('Update Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }
}
