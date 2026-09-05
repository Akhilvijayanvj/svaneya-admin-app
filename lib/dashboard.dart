import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'screens/overview.dart';
import 'screens/products.dart';
import 'screens/orders.dart';
import 'screens/settings.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [
        OverviewScreen(onNavigate: (idx) => setState(() => _currentIndex = idx)),
        const ProductsScreen(),
        const OrdersScreen(),
        const SettingsScreen(),
      ][_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(LucideIcons.layoutDashboard), label: 'Overview'),
          NavigationDestination(icon: Icon(LucideIcons.package), label: 'Products'),
          NavigationDestination(icon: Icon(LucideIcons.shoppingBag), label: 'Orders'),
          NavigationDestination(icon: Icon(LucideIcons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
