import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../main.dart';

class MobileBannerScreen extends StatefulWidget {
  const MobileBannerScreen({super.key});

  @override
  State<MobileBannerScreen> createState() => _MobileBannerScreenState();
}

class _MobileBannerScreenState extends State<MobileBannerScreen> {
  bool _isLoading = true;
  
  // Web Banner State
  String? _webBannerUrl;

  // Mobile Banners State
  List<dynamic> _mobileBanners = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch Web Banner
      final webRes = await supabase.from('store_settings').select('hero_image_1').eq('id', 'global').maybeSingle();
      if (webRes != null) {
        _webBannerUrl = webRes['hero_image_1'];
      }

      // Fetch Mobile Banners
      final mobileRes = await supabase.from('mobile_banners').select().order('sort_order', ascending: true);
      _mobileBanners = mobileRes;

    } catch (e) {
      debugPrint("Error fetching banners: $e");
    } finally {
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
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Web Banner updated!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _uploadMobileBanner() async {
    if (_mobileBanners.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 4 mobile banners allowed.')));
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final file = File(image.path);
      final fileName = 'mobile_banner_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('product-images').upload(fileName, file);
      final url = supabase.storage.from('product-images').getPublicUrl(fileName);

      await supabase.from('mobile_banners').insert({
        'image_url': url,
        'sort_order': _mobileBanners.length,
      });
      
      await _fetchData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mobile Banner added!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteMobileBanner(String id) async {
    setState(() => _isUploading = true);
    try {
      await supabase.from('mobile_banners').delete().eq('id', id);
      await _fetchData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting banner: $e')));
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
        title: const Text('App Banners', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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
                    // --- WEB BANNER SECTION ---
                    const Text('Website Banner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                              child: Image.network(_webBannerUrl!, height: 120, width: double.infinity, fit: BoxFit.cover),
                            )
                          else
                            Container(
                              height: 120, width: double.infinity,
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                              child: const Center(child: Text('No Web Banner Set', style: TextStyle(color: Colors.grey))),
                            ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _uploadWebBanner,
                            icon: const Icon(LucideIcons.uploadCloud, size: 18),
                            label: const Text('Update Website Banner', style: TextStyle(fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          )
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // --- MOBILE BANNERS SECTION ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Mobile App Banners', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('${_mobileBanners.length}/4', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Add up to 4 scrolling banners for the mobile customer app.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 16),
                    
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _mobileBanners.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final banner = _mobileBanners[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200)
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                child: Image.network(banner['image_url'], width: 100, height: 70, fit: BoxFit.cover),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text('Banner ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
                                onPressed: () => _deleteMobileBanner(banner['id']),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        );
                      },
                    ),
                    
                    if (_mobileBanners.length < 4) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _uploadMobileBanner,
                        icon: const Icon(LucideIcons.plus, size: 18),
                        label: const Text('Add Mobile Banner', style: TextStyle(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: const Color(0xFFBFFF07),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    ],
                    const SizedBox(height: 40),
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
