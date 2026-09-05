import 'package:flutter/material.dart';
import '../main.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(LucideIcons.user),
            title: Text('Admin Account'),
            subtitle: Text('Manage your store profile'),
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
