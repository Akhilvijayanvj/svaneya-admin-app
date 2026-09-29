import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../main.dart';

class WebBannerScreen extends StatefulWidget {
  const WebBannerScreen({super.key});

  @override
  State<WebBannerScreen> createState() => _WebBannerScreenState();
}

class _WebBannerScreenState extends State<WebBannerScreen> {
  bool _isLoading = true;
  bool _isUploading = false;
  
  String? _webBannerUrl;
  bool _saleActive = false;
  final _saleTextCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final res = await supabase.from('store_settings').select('hero_image_1, sale_active, sale_text').eq('id', 'global').maybeSingle();
      if (mounted) {
        setState(() {
          if (res != null) {
            _webBannerUrl = res['hero_image_1'];
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

  Future<void> _uploadWebBanner() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final file = File(image.path);
      final fileName = 'web_banner_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('product-images').upload(fileName, file);
      final url = supabase.storage.from('product-images').getPublicUrl(fileName);

      await supabase.from('store_settings').update({'hero_image_1': url}).eq('id', 'global');
      await _fetchData();
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Website Hero Image updated!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveTextBanner() async {
    setState(() => _isUploading = true);
    try {
      await supabase.from('store_settings').update({
        'sale_active': _saleActive,
        'sale_text': _saleTextCtrl.text,
      }).eq('id', 'global');
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement Banner saved!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Website Banners', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.black)) 
        : Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Website Hero Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text('This single image is displayed at the top of the website storefront.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 16),
                    
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (_webBannerUrl != null && _webBannerUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(_webBannerUrl!, height: 160, width: double.infinity, fit: BoxFit.cover),
                            )
                          else
                            Container(
                              height: 160, width: double.infinity,
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                              child: const Center(child: Text('No Web Banner Set', style: TextStyle(color: Colors.grey))),
                            ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _uploadWebBanner,
                            icon: const Icon(LucideIcons.uploadCloud, size: 18),
                            label: const Text('Pick Image from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              minimumSize: const Size(double.infinity, 50)
                            ),
                          )
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    const Text('Text Announcement Banner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text('This scrolling text banner is displayed at the very top of the website.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Enable Text Banner', style: TextStyle(fontWeight: FontWeight.w600)),
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
                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: _saveTextBanner,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B), 
                          foregroundColor: const Color(0xFFBFFF07),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        child: const Text('SAVE TEXT BANNER', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    )
                  ],
                ),
              ),
              if (_isUploading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator(color: Color(0xFFBFFF07))),
                ),
            ],
          ),
    );
  }
}
