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
    final currentStatus = (_order!['status'] ?? 'pending').toString().toLowerCase();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('Update Order Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            _buildStatusOption('pending', LucideIcons.clock, Colors.orange, currentStatus == 'pending'),
            _buildStatusOption('paid', LucideIcons.checkCircle2, Colors.green, currentStatus == 'paid'),
            _buildStatusOption('shipped', LucideIcons.truck, Colors.blue, currentStatus == 'shipped'),
            _buildStatusOption('delivered', LucideIcons.packageCheck, Colors.purple, currentStatus == 'delivered'),
            _buildStatusOption('cancelled', LucideIcons.xCircle, Colors.red, currentStatus == 'cancelled'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(String s, IconData icon, MaterialColor color, bool isSelected) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        setState(() => _isLoading = true);
        await supabase.from('orders').update({'status': s}).eq('id', widget.orderId);
        _fetchOrder();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color.shade200 : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey.shade600, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                s.toUpperCase(),
                style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? color.shade700 : Colors.black87),
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
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
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text('Order #$shortId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status & Date row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                  child: Text(status, style: TextStyle(color: statusText, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Text(DateFormat('MMM d, yyyy • h:mm a').format(date), style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
            if (_order!['payment_id'] != null) ...[
              const SizedBox(height: 16),
              Text('Payment ID: ${_order!['payment_id']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            
            // Customer Info Full Width Card
            const Text('Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 24, backgroundColor: const Color(0xFF1E293B), child: Text(_order!['customer_name'][0].toUpperCase(), style: const TextStyle(color: Color(0xFFBFFF07), fontWeight: FontWeight.bold, fontSize: 18))),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_order!['customer_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 2),
                            Text(_order!['customer_email'] ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                  Row(
                    children: [
                      const Icon(LucideIcons.phone, size: 18, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_order!['customer_phone'] ?? 'No phone number provided', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(LucideIcons.messageCircle, size: 18),
                          label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(LucideIcons.phoneCall, size: 18),
                          label: const Text('Call', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Shipping Address Full Width Card
            const Text('Shipping Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, size: 18, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(address['city'] ?? 'No city', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(address['address'] ?? 'No address provided', style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.5)),
                        const SizedBox(height: 4),
                        Text('${address['state'] ?? ''} - ${address['pin'] ?? ''}', style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Order Items
            Text('Items (${_items.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
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
                              Text(p != null ? p['name'] : 'Product', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 6),
                              Text('Qty: ${i['quantity']}  ×  ₹${i['price']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        Text('₹${(i['quantity'] * i['price']).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            
            // Order Summary
            const Text('Payment Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Subtotal', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    Text('₹${_order!['total_amount']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ]),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Shipping', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    const Text('Free', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.green)),
                  ]),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('₹${_order!['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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
