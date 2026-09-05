import 'package:flutter/material.dart';
import '../main.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'promo_codes.dart';
import 'mobile_banner.dart';
import 'notifications.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Store Configuration')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(LucideIcons.user),
            title: Text('Admin Account'),
            subtitle: Text('Manage your store profile'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(LucideIcons.tags),
            title: const Text('Promo Codes'),
            subtitle: const Text('Create and manage discounts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PromoCodesScreen())),
          ),
          ListTile(
            leading: const Icon(LucideIcons.bell),
            title: const Text('Push Notifications'),
            subtitle: const Text('Send alerts to mobile users'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          ListTile(
            leading: const Icon(LucideIcons.image),
            title: const Text('Mobile Banner'),
            subtitle: const Text('Update the app homepage banner'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileBannerScreen())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(LucideIcons.logOut, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await supabase.auth.signOut();
            },
          ),
        ],
      ),
    );
  }
}
