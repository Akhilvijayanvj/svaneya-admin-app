import 'package:flutter/material.dart';
import '../main.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PromoCodesScreen extends StatefulWidget {
  const PromoCodesScreen({super.key});

  @override
  State<PromoCodesScreen> createState() => _PromoCodesScreenState();
}

class _PromoCodesScreenState extends State<PromoCodesScreen> {
  bool _isLoading = true;
  List<dynamic> _promos = [];

  @override
  void initState() {
    super.initState();
    _fetchPromos();
  }

  Future<void> _fetchPromos() async {
    try {
      final res = await supabase.from('promo_codes').select().order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _promos = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addPromo() {
    // Basic dialog to add promo code
    final codeCtrl = TextEditingController();
    final typeCtrl = TextEditingController(text: 'percentage');
    final amountCtrl = TextEditingController();
    
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Add Promo Code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code (e.g. SUMMER20)')),
          TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Type (percentage or fixed)')),
          TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Amount (e.g. 20)'), keyboardType: TextInputType.number),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (codeCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;
            await supabase.from('promo_codes').insert({
              'code': codeCtrl.text.toUpperCase(),
              'discount_type': typeCtrl.text,
              'discount_amount': double.parse(amountCtrl.text),
              'is_active': true
            });
            if (mounted) Navigator.pop(context);
            _fetchPromos();
          }, 
          child: const Text('Save')
        )
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promo Codes'),
        actions: [IconButton(icon: const Icon(LucideIcons.plus), onPressed: _addPromo)],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        itemCount: _promos.length,
        itemBuilder: (context, index) {
          final p = _promos[index];
          return ListTile(
            title: Text(p['code'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Text('${p['discount_amount']} ${p['discount_type']}'),
            trailing: Switch(
              value: p['is_active'] ?? true,
              onChanged: (val) async {
                await supabase.from('promo_codes').update({'is_active': val}).eq('id', p['id']);
                _fetchPromos();
              },
            ),
          );
        },
      ),
    );
  }
}
