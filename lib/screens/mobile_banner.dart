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
  List<dynamic> _mobileBanners = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    setState(() => _isLoading = true);
    try {
      final mobileRes = await supabase.from('mobile_banners').select().order('sort_order', ascending: true);
      _mobileBanners = mobileRes;
    } catch (e) {
      debugPrint("Error fetching banners: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadMobileBanner() async {
    if (_mobileBanners.length >= 4) return;

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
      
      await _fetchBanners();
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
      await _fetchBanners();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting banner: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canUpload = _mobileBanners.length < 4;

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Hero Slider Banners', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('${_mobileBanners.length}/4', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('These images scroll in the mobile customer app. Max 4 photos allowed.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 24),
                    
                    if (_mobileBanners.isEmpty)
                      Container(
                        height: 150, width: double.infinity,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                        child: const Center(child: Text('No banners uploaded yet.', style: TextStyle(color: Colors.grey))),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: _mobileBanners.length,
                        itemBuilder: (context, index) {
                          final banner = _mobileBanners[index];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(banner['image_url'], width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 4, right: 4,
                                child: GestureDetector(
                                  onTap: () => _deleteMobileBanner(banner['id']),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                  ),
                                ),
                              )
                            ],
                          );
                        },
                      ),
                    
                    const SizedBox(height: 32),
                    
                    ElevatedButton.icon(
                      onPressed: canUpload ? _uploadMobileBanner : null,
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: const Text('Add Mobile Banner', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: const Color(0xFFBFFF07),
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
