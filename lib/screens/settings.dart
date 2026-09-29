import 'package:flutter/material.dart';
import '../main.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'promo_codes.dart';
import 'mobile_banner.dart';
import 'notifications.dart';
import 'categories.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('More', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=Admin&background=1E293B&color=BFFF07'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Admin User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('admin@svaneya.com', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  _buildListItem(LucideIcons.user, 'Profile Settings', 'Manage your account', () {}),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Removed Main Settings (Moved to Dashboard Quick Actions)


            // System Settings
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildListItem(LucideIcons.moon, 'App Appearance', 'Light / Dark mode', () {}),
                  const Divider(height: 1, indent: 56),
                  _buildListItem(LucideIcons.info, 'About', 'Version 1.0.0', () {}),
                  const Divider(height: 1, indent: 56),
                  _buildListItem(LucideIcons.logOut, 'Logout', 'Sign out of admin account', () async {
                    await supabase.auth.signOut();
                  }, isDestructive: true),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(IconData icon, String title, String subtitle, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? Colors.red : Colors.black;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: color, size: 22),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 14)),
      subtitle: subtitle.isNotEmpty ? Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}
