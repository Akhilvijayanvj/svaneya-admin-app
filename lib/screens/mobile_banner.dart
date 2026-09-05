import 'package:flutter/material.dart';
import '../main.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MobileBannerScreen extends StatefulWidget {
  const MobileBannerScreen({super.key});

  @override
  State<MobileBannerScreen> createState() => _MobileBannerScreenState();
}

class _MobileBannerScreenState extends State<MobileBannerScreen> {
  final _urlCtrl = TextEditingController();
  bool _isLoading = true;
  String? _currentUrl;

  @override
  void initState() {
    super.initState();
    _fetchBanner();
  }

  Future<void> _fetchBanner() async {
    try {
      final res = await supabase.from('store_settings').select('hero_image_1').eq('id', 'global').maybeSingle();
      if (mounted) {
        setState(() {
          if (res != null) {
            _currentUrl = res['hero_image_1'];
            _urlCtrl.text = _currentUrl ?? '';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBanner() async {
    if (_urlCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    
    await supabase.from('store_settings').update({'hero_image_1': _urlCtrl.text}).eq('id', 'global');
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banner saved!')));
    _fetchBanner();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mobile Banner')),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current Banner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            if (_currentUrl != null && _currentUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(_currentUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
              )
            else
              Container(
                height: 150, width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('No Banner Set')),
              ),
            const SizedBox(height: 32),
            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(labelText: 'Banner Image URL', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _saveBanner,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink.shade600, foregroundColor: Colors.white),
                child: const Text('SAVE BANNER'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
