import 'package:flutter/material.dart';
import '../main.dart';
import 'package:intl/intl.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool _isLoading = true;
  List<dynamic> _alerts = [];
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    try {
      final res = await supabase.from('admin_notifications').select().order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _alerts = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _dismissAlert(String id) async {
    await supabase.from('admin_notifications').update({'is_read': true}).eq('id', id);
    _fetchAlerts();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _alerts.where((a) {
      if (_filter == 'All') return true;
      if (_filter == 'Order Issues') return (a['title'] ?? '').toString().toLowerCase().contains('order');
      if (_filter == 'Low Stock') return (a['title'] ?? '').toString().toLowerCase().contains('stock');
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black)),
            Text('Things that need your attention', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ],
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black), onPressed: () {}),
          const SizedBox(width: 8)
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', _filter == 'All'),
                _buildFilterChip('Order Issues', _filter == 'Order Issues', count: _alerts.where((a) => (a['title'] ?? '').toString().toLowerCase().contains('order')).length),
                _buildFilterChip('Low Stock', _filter == 'Low Stock', count: _alerts.where((a) => (a['title'] ?? '').toString().toLowerCase().contains('stock')).length),
                _buildFilterChip('Reviews', _filter == 'Reviews'),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchAlerts,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final a = filtered[index];
                  final isRead = a['is_read'] == true;
                  final title = a['title'] ?? '';
                  final isLowStock = title.toLowerCase().contains('stock');
                  final iconColor = isRead ? Colors.grey : (isLowStock ? Colors.orange : Colors.deepOrange);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isRead ? Colors.grey.shade100 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isRead ? Colors.grey.shade300 : Colors.orange.shade200)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.circle, size: 10, color: iconColor),
                            const SizedBox(width: 8),
                            Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isRead ? Colors.grey.shade800 : Colors.orange.shade900, fontSize: 16))),
                            if (!isRead)
                              InkWell(
                                onTap: () => _dismissAlert(a['id']),
                                child: Text('Dismiss', style: TextStyle(color: Colors.orange.shade700, fontSize: 13, decoration: TextDecoration.underline)),
                              )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(a['message'] ?? '', style: TextStyle(color: isRead ? Colors.grey.shade600 : Colors.orange.shade800, fontSize: 14, height: 1.4)),
                        const SizedBox(height: 12),
                        Text(DateFormat('M/d/yyyy, h:mm:ss a').format(DateTime.parse(a['created_at']).toLocal()), style: TextStyle(color: isRead ? Colors.grey.shade500 : Colors.orange.shade400, fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, {int count = 0}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(
          children: [
            Text(label),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: isSelected ? Colors.white24 : Colors.red.shade100, borderRadius: BorderRadius.circular(10)),
                child: Text('$count', style: TextStyle(color: isSelected ? Colors.white : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ]
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
