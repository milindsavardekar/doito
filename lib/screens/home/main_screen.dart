// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../../theme/app_theme.dart';
// import 'home_screen.dart';
// import '../bookings/bookings_list_screen.dart';
// import '../profile/profile_screen.dart';
// import '../services/services_browse_screen.dart';

// class MainScreen extends StatefulWidget {
//   const MainScreen({super.key});

//   @override
//   State<MainScreen> createState() => _MainScreenState();
// }

// class _MainScreenState extends State<MainScreen> {
//   int _currentIndex = 0;

//   // ✅ Sirf 4 screens - match with bottom nav items
//   final _screens = const [
//     HomeScreen(),           // Index 0 - Home
//     ServicesBrowseScreen(), // Index 1 - Services  
//     BookingsListScreen(),   // Index 2 - Bookings
//     ProfileScreen(),        // Index 3 - Profile
//   ];

//   @override
//   void initState() {
//     super.initState();
//     SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
//       statusBarColor: Colors.transparent,
//       statusBarIconBrightness: Brightness.light,
//     ));
//   }

//   // ✅ Add this method to change tab from other screens
//   void changeTab(int index) {
//     setState(() {
//       _currentIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: IndexedStack(index: _currentIndex, children: _screens),
//       bottomNavigationBar: _buildNavBar(),
//     );
//   }

//   Widget _buildNavBar() {
//     const items = [
//       {'icon': Icons.home_outlined, 'activeIcon': Icons.home_rounded, 'label': 'Home'},
//       {'icon': Icons.home_repair_service_outlined, 'activeIcon': Icons.home_repair_service_rounded, 'label': 'Services'},
//       {'icon': Icons.calendar_today_outlined, 'activeIcon': Icons.calendar_today_rounded, 'label': 'Bookings'},
//       {'icon': Icons.person_outline_rounded, 'activeIcon': Icons.person_rounded, 'label': 'Profile'},
//     ];

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.08),
//             blurRadius: 24,
//             offset: const Offset(0, -4),
//           ),
//         ],
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       child: ClipRRect(
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//         child: SafeArea(
//           top: false,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: List.generate(
//                 items.length,
//                 (i) => _NavItem(
//                   icon: items[i]['icon'] as IconData,
//                   activeIcon: items[i]['activeIcon'] as IconData,
//                   label: items[i]['label'] as String,
//                   isActive: _currentIndex == i,
//                   onTap: () => setState(() => _currentIndex = i),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _NavItem extends StatelessWidget {
//   final IconData icon;
//   final IconData activeIcon;
//   final String label;
//   final bool isActive;
//   final VoidCallback onTap;

//   const _NavItem({
//     required this.icon,
//     required this.activeIcon,
//     required this.label,
//     required this.isActive,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       behavior: HitTestBehavior.opaque,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
//         decoration: BoxDecoration(
//           color: isActive ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               isActive ? activeIcon : icon,
//               color: isActive ? AppTheme.primary : AppTheme.textLight,
//               size: 24,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 color: isActive ? AppTheme.primary : AppTheme.textLight,
//                 fontSize: 11,
//                 fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart';
import '../bookings/bookings_list_screen.dart';
import '../profile/profile_screen.dart';
import '../nearby/nearby_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  final _screens = const [
    HomeScreen(),           // Index 0 - Home
    NearbyScreen(),         // Index 1 - Nearby
    BookingsListScreen(),   // Index 2 - Bookings
    ProfileScreen(),        // Index 3 - Profile
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    const items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.location_searching_outlined, 'activeIcon': Icons.location_searching_rounded, 'label': 'Nearby'},
      {'icon': Icons.calendar_today_outlined, 'activeIcon': Icons.calendar_today_rounded, 'label': 'Bookings'},
      {'icon': Icons.person_outline_rounded, 'activeIcon': Icons.person_rounded, 'label': 'Profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
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
                  activeIcon: items[i]['activeIcon'] as IconData,
                  label: items[i]['label'] as String,
                  isActive: _currentIndex == i,
                  onTap: () => setState(() => _currentIndex = i),
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
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppTheme.primary : AppTheme.textLight,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primary : AppTheme.textLight,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}