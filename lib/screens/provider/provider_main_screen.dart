import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import 'provider_home_screen.dart';
import 'provider_bookings_screen.dart';
import 'provider_profile_screen.dart';
import '../services/manage_listings_screen.dart';

class ProviderMainScreen extends StatefulWidget {
  const ProviderMainScreen({super.key});

  @override
  State<ProviderMainScreen> createState() => _ProviderMainScreenState();
}

class _ProviderMainScreenState extends State<ProviderMainScreen> {
  int _index = 0;

  final _screens = const [
    ProviderHomeScreen(),
    ManageListingsScreen(),
    ProviderBookingsScreen(),
    ProviderProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    final items = [
      {'icon': Icons.dashboard_outlined, 'active': Icons.dashboard_rounded, 'label': 'Dashboard'},
      {'icon': Icons.list_alt_outlined, 'active': Icons.list_alt_rounded, 'label': 'My Services'},
      {'icon': Icons.calendar_today_outlined, 'active': Icons.calendar_today_rounded, 'label': 'Bookings'},
      {'icon': Icons.person_outline_rounded, 'active': Icons.person_rounded, 'label': 'Profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -4)),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                items.length,
                (i) => _NavItem(
                  icon: items[i]['icon'] as IconData,
                  activeIcon: items[i]['active'] as IconData,
                  label: items[i]['label'] as String,
                  isActive: _index == i,
                  onTap: () => setState(() => _index = i),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon, required this.activeIcon, required this.label,
    required this.isActive, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon,
                color: isActive ? AppTheme.primary : AppTheme.textLight,
                size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: isActive ? AppTheme.primary : AppTheme.textLight,
                    fontSize: 10,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
