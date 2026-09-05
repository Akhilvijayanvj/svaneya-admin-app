import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'screens/overview.dart';
import 'screens/products.dart';
import 'screens/orders.dart';
import 'screens/alerts.dart';
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: [
        OverviewScreen(onNavigate: (idx) => setState(() => _currentIndex = idx)),
        const ProductsScreen(),
        const OrdersScreen(),
        const AlertsScreen(),
        const SettingsScreen(),
      ][_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(0, LucideIcons.layoutDashboard, 'Dashboard'),
                _buildNavItem(1, LucideIcons.package, 'Products'),
                _buildNavItem(2, LucideIcons.shoppingCart, 'Orders'),
                _buildNavItem(3, LucideIcons.bellRing, 'Alerts', badge: true),
                _buildNavItem(4, LucideIcons.menu, 'More'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {bool badge = false}) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Icon(icon, color: isSelected ? const Color(0xFFBFFF07) : Colors.grey.shade500, size: 22),
                if (badge && !isSelected)
                  Positioned(right: 0, top: 0, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ]
          ],
        ),
      ),
    );
  }
}
