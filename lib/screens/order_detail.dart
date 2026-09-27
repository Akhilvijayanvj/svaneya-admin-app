import 'package:flutter/material.dart';
import '../main.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

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

    final shortId = _order!['id'].toString().substring(0, 8).toLowerCase();
    final date = DateTime.parse(_order!['created_at']).toLocal();
    final status = (_order!['status'] ?? 'pending').toString().toUpperCase();
    
    Color statusBg = Colors.grey.shade100;
    Color statusText = Colors.grey.shade700;
    if (status == 'PAID') { statusBg = Colors.green.shade50; statusText = Colors.green; }
    else if (status == 'SHIPPED') { statusBg = Colors.blue.shade50; statusText = Colors.blue; }
    else if (status == 'DELIVERED') { statusBg = Colors.purple.shade50; statusText = Colors.purple; }
    else if (status == 'CANCELLED') { statusBg = Colors.red.shade50; statusText = Colors.red; }

    Map<String, dynamic> address = {};
    if (_order!['shipping_address'] is Map) {
      address = _order!['shipping_address'] as Map<String, dynamic>;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, size: 24, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text('Order Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Order #$shortId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(status, style: TextStyle(color: statusText, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showStatusDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Text(status.toLowerCase(), style: const TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, size: 16),
                      ],
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(DateFormat('M/d/yyyy, h:mm:ss a').format(date), style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            const SizedBox(height: 4),
            Text('Payment ID: ${_order!['payment_id'] ?? 'N/A'}', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            
            const SizedBox(height: 24),
            
            // Cards Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(radius: 20, backgroundColor: Colors.blue.shade100, child: Text(_order!['customer_name'][0].toUpperCase(), style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold))),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_order!['customer_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(_order!['customer_email'] ?? '', style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                        Text(_order!['customer_phone'] ?? 'No phone', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(LucideIcons.messageCircle, size: 16, color: Colors.white),
                                label: const Text('WhatsApp', style: TextStyle(fontSize: 13)),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 10)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(LucideIcons.phone, size: 16, color: Colors.white),
                                label: const Text('Call', style: TextStyle(fontSize: 13)),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 10)),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Shipping Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Shipping Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                        Text(address['address'] ?? 'No address', style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 14, height: 1.5)),
                        const SizedBox(height: 4),
                        Text('${address['city'] ?? ''}, ${address['state'] ?? ''}', style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 14, height: 1.5)),
                        const SizedBox(height: 4),
                        Text('PIN: ${address['pin'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Items
            const Text('Order Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
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
                              Text('Qty: ${i['quantity']} × ₹${i['price']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                            ],
                          ),
                        ),
                        Text('₹${(i['quantity'] * i['price']).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            
            // Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount Paid:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('₹${_order!['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
