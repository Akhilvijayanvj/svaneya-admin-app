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
  final _saleTextCtrl = TextEditingController();
  bool _isLoading = true;
  String? _currentUrl;
  bool _saleActive = false;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    try {
      final res = await supabase.from('store_settings').select('hero_image_1, sale_active, sale_text').eq('id', 'global').maybeSingle();
      if (mounted) {
        setState(() {
          if (res != null) {
            _currentUrl = res['hero_image_1'];
            _urlCtrl.text = _currentUrl ?? '';
            _saleActive = res['sale_active'] ?? false;
            _saleTextCtrl.text = res['sale_text'] ?? '';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBanners() async {
    setState(() => _isLoading = true);
    
    await supabase.from('store_settings').update({
      'hero_image_1': _urlCtrl.text,
      'sale_active': _saleActive,
      'sale_text': _saleTextCtrl.text,
    }).eq('id', 'global');
    
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banners saved successfully!')));
    _fetchBanners();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Banners', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: Colors.black)) : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mobile Banner Section
            const Text('Mobile App Banner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('This image is displayed at the top of the mobile customer app.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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
            const SizedBox(height: 16),
            TextField(
              controller: _urlCtrl,
              decoration: InputDecoration(
                labelText: 'Banner Image URL',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Web Sale Announcement Banner
            const Text('Web Announcement Banner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('This scrolling text banner is displayed at the top of the website.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Enable Web Banner', style: TextStyle(fontWeight: FontWeight.w600)),
                      Switch(
                        value: _saleActive,
                        activeColor: const Color(0xFFBFFF07),
                        onChanged: (val) => setState(() => _saleActive = val),
                      ),
                    ],
                  ),
                  if (_saleActive) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _saleTextCtrl,
                      decoration: InputDecoration(
                        labelText: 'Announcement Text',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ]
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _saveBanners,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B), 
                  foregroundColor: const Color(0xFFBFFF07),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                child: const Text('SAVE BANNERS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
