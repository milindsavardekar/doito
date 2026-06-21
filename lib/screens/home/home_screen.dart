import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/models.dart';
import '../../services/firebase_services.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../services/services_browse_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  String get _selectedLocation => LocationService.selected.value;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    LocationService.selected.addListener(_onLocationChanged);
  }

  @override
  void dispose() {
    LocationService.selected.removeListener(_onLocationChanged);
    super.dispose();
  }

  void _onLocationChanged() {
    if (mounted) setState(() {});
  }

  void _loadUserName() async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) return;
    final user = await AuthService().resolveUserForLogin(
      uid: fbUser.uid,
      phone: fbUser.phoneNumber ?? '',
    );
    if (mounted && user != null) {
      setState(() => _userName = user.name.split(' ').first);
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning ☀️';
    if (h < 17) return 'Good Afternoon 👋';
    return 'Good Evening 🌙';
  }

  // No Marathi map needed — English only

  void _changeLocation() async {
    final TextEditingController manualCtrl = TextEditingController();
    String searchFilter = '';

    final newLocation = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModal) {
          final filtered = kSangliLocations
              .where((loc) =>
                  loc.toLowerCase().contains(searchFilter.toLowerCase()))
              .toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder: (_, sc) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        const Text('Select Location',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  // Search / Manual type field
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: TextField(
                      controller: manualCtrl,
                      onChanged: (v) => setModal(() => searchFilter = v),
                      decoration: InputDecoration(
                        hintText: 'Search or type location...',
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppTheme.primary),
                        suffixIcon: manualCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  manualCtrl.clear();
                                  setModal(() => searchFilter = '');
                                })
                            : null,
                        filled: true,
                        fillColor: AppTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  // Manual entry button — shown when typed text doesn't match any
                  if (manualCtrl.text.trim().isNotEmpty &&
                      !kSangliLocations.any((l) =>
                          l.toLowerCase() ==
                          manualCtrl.text.trim().toLowerCase()))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: InkWell(
                        onTap: () =>
                            Navigator.pop(ctx, manualCtrl.text.trim()),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    AppTheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add_location_alt_rounded,
                                  color: AppTheme.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Use "${manualCtrl.text.trim()}"',
                                      style: const TextStyle(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13),
                                    ),
                                    const Text(
                                      'Use this custom location',
                                      style: TextStyle(
                                          color: AppTheme.textLight,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: sc,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final loc = filtered[i];
                        final isSelected = loc == _selectedLocation;
                        return ListTile(
                          leading: Icon(
                            Icons.location_on_rounded,
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.textLight,
                            size: 20,
                          ),
                          title: Text(
                            loc,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded,
                                  color: AppTheme.primary, size: 18)
                              : null,
                          onTap: () => Navigator.pop(ctx, loc),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );

    if (newLocation != null && newLocation != _selectedLocation) {
      LocationService.set(newLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildPromoCard()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'All Services',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    _selectedLocation,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildCategoriesGrid()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ── App Bar ─────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.primary,
      automaticallyImplyLeading: false,
      toolbarHeight: 70,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(3),
            child: Image.asset(
              'assets/images/doito_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _greeting(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _userName.isEmpty ? 'Welcome!' : _userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: _changeLocation,
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    _selectedLocation,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Search Bar ──────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: AppTheme.primary,
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ServicesBrowseScreen(
                  initialLocation: _selectedLocation,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, color: AppTheme.primary, size: 22),
                  SizedBox(width: 12),
                  Text(
                    'Search services...',
                    style: TextStyle(color: AppTheme.textLight, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

 // ── Promo Card ──────────────────────────────────────────────────────────────
Widget _buildPromoCard() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
    child: Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background decorative circle
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            // Main content - Image now fills full height
            Row(
              children: [
                // Left side - Text content
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '🎉 Special Offer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'सर्व सेवा एकाच ठिकाणी\nअतिरिक्त शुल्का शिवाय!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // GestureDetector(
                        //   onTap: () => Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //       builder: (_) => ServicesBrowseScreen(
                        //         initialLocation: _selectedLocation,
                        //       ),
                        //     ),
                        //   ),
                        //   child: Container(
                        //     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        //     decoration: BoxDecoration(
                        //       color: Colors.white,
                        //       borderRadius: BorderRadius.circular(20),
                        //     ),
                        //     child: const Text(
                        //       'Browse Services →',
                        //       style: TextStyle(
                        //         color: AppTheme.primary,
                        //         fontSize: 11,
                        //         fontWeight: FontWeight.w700,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
                // ✅ Right side - PNG Image (FULL HEIGHT - upar neeche touch)
                Expanded(
                  flex: 1,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    child: Image.asset(
                      'assets/images/promo_image.png',
                      height: double.infinity,  // ✅ Full height
                      width: double.infinity,
                      fit: BoxFit.cover,        // ✅ Cover full area
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  // ── Categories Grid - 3 Cards per Row ──────────────────────────────────
  Widget _buildCategoriesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
          childAspectRatio: 0.95,
        ),
        itemCount: MockData.categories.length,
        itemBuilder: (_, i) {
          final cat = MockData.categories[i];
          final color = AppTheme.primary;
          return _CategoryCard(
            category: cat,
            color: color,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ServicesBrowseScreen(
                  initialCategory: cat.name,
                  initialLocation: _selectedLocation,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Category Card ─────────────────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final ServiceCategory category;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  category.iconData,
                  size: 32,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../../models/models.dart';
// import '../services/firebase_services.dart';
// import '../../theme/app_theme.dart';
// import '../../widgets/common_widgets.dart';
// import '../services/service_listing_detail_screen.dart';
// import '../services/services_browse_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final _firestore = FirestoreService();
//   String _userName = '';
//   String _selectedLocation = 'Sangli - Vishrambag';

//   final List<String> _availableLocations = [
//     'Sangli - Yashwantnagar',
//     'Sangli - Madhavnagar',
//     'Sangli - Vijaynagar',
//     'Sangli - Sangliwadi',
//     'Sangli - Miraj',
//     'Sangli - Gaonbhag',
//     'Sangli - Khanbhag',
//     'Sangli - Ganeshnagar',
//     'Sangli - Kupwad',
//     'Sangli - Bamani',
//     'Sangli - Bamnoli',
//     'Sangli - Vishrambag',
//     'Sangli - Nalbhag',
//     'Sangli - Sanjaynagar',
//     'Sangli - Wanlesswadi',
//     'Sangli - Shamraonagar',
//     'Sangli - Haripur Road',
//     'Sangli - Haripur',
//     'Sangli - Rukmini Nagar',
//     'Sangli - Shastri Nagar',
//     'Sangli - Ashok Nagar',
//     'Sangli - Shinde Nagar',
//     'Sangli - Dhanwantari Nagar',
//     'Sangli - Shivarampur',
//     'Sangli - Harshwardhan Nagar',
//     'Sangli - Shivaji Nagar',
//     'Sangli - Ganpati Nagar',
//     'Sangli - Dhamni',
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _loadUserName();
//   }

//   void _loadUserName() async {
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) return;
//     final user = await AuthService().getUserData(uid);
//     if (mounted && user != null) {
//       setState(() => _userName = user.name.split(' ').first);
//     }
//   }

//   String _greeting() {
//     final h = DateTime.now().hour;
//     if (h < 12) return 'Good Morning ☀️';
//     if (h < 17) return 'Good Afternoon 👋';
//     return 'Good Evening 🌙';
//   }

//   void _changeLocation() async {
//     final newLocation = await showDialog<String>(
//       context: context,
//       builder: (ctx) => SimpleDialog(
//         title: const Text(
//           'Select your location',
//           style: TextStyle(fontWeight: FontWeight.w600),
//         ),
//         children: _availableLocations.map((loc) => SimpleDialogOption(
//           onPressed: () => Navigator.pop(ctx, loc),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8),
//             child: Row(
//               children: [
//                 const Icon(Icons.location_on_outlined, size: 18, color: AppTheme.primary),
//                 const SizedBox(width: 12),
//                 Text(loc, style: const TextStyle(fontSize: 14)),
//               ],
//             ),
//           ),
//         )).toList(),
//       ),
//     );
//     if (newLocation != null && newLocation != _selectedLocation) {
//       setState(() => _selectedLocation = newLocation);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppTheme.surface,
//       body: CustomScrollView(
//         slivers: [
//           _buildAppBar(),
//           SliverToBoxAdapter(child: _buildSearchBar()),
//           SliverToBoxAdapter(child: _buildPromoCard()),
//           SliverToBoxAdapter(child: _buildCategories()),
//           SliverToBoxAdapter(
//             child: SectionHeader(
//               title: 'Latest Services in $_selectedLocation',
//               action: 'See all',
//               onAction: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => ServicesBrowseScreen(initialLocation: _selectedLocation),
//                 ),
//               ),
//             ),
//           ),
//           SliverToBoxAdapter(child: _buildLatestServices()),
//           const SliverToBoxAdapter(child: SizedBox(height: 100)),
//         ],
//       ),
//     );
//   }

//   // ── App Bar with Location Selector ─────────────────────────────────────────
//   Widget _buildAppBar() {
//     return SliverAppBar(
//       pinned: true,
//       backgroundColor: AppTheme.primary,
//       automaticallyImplyLeading: false,
//       flexibleSpace: FlexibleSpaceBar(
//         background: Container(
//           decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
//         ),
//       ),
//       title: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             _greeting(),
//             style: const TextStyle(
//               color: Colors.white70,
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           Text(
//             _userName.isEmpty ? 'Welcome!' : _userName,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//         ],
//       ),
//       actions: [
//         // Location Selector Button (OLX Style)
//         GestureDetector(
//           onTap: _changeLocation,
//           child: Container(
//             margin: const EdgeInsets.only(right: 16),
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//             decoration: BoxDecoration(
//               color: Colors.white.withValues(alpha: 0.2),
//               borderRadius: BorderRadius.circular(24),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
//                 const SizedBox(width: 6),
//                 ConstrainedBox(
//                   constraints: const BoxConstraints(maxWidth: 140),
//                   child: Text(
//                     _selectedLocation,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w500,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                     maxLines: 1,
//                   ),
//                 ),
//                 const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
//               ],
//             ),
//           ),
//         ),
//         // Profile Icon
//         Container(
//           width: 38,
//           height: 38,
//           margin: const EdgeInsets.only(right: 16),
//           decoration: BoxDecoration(
//             color: Colors.white.withValues(alpha: 0.2),
//             shape: BoxShape.circle,
//             border: Border.all(color: Colors.white30, width: 2),
//           ),
//           child: const Icon(Icons.person, color: Colors.white, size: 20),
//         ),
//       ],
//     );
//   }

//   // ── Search Bar ──────────────────────────────────────────────────────────────
//   Widget _buildSearchBar() {
//     return Container(
//       color: AppTheme.primary,
//       child: Container(
//         decoration: const BoxDecoration(
//           color: AppTheme.surface,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(28),
//             topRight: Radius.circular(28),
//           ),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
//           child: GestureDetector(
//             onTap: () => Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => ServicesBrowseScreen(initialLocation: _selectedLocation),
//               ),
//             ),
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: AppTheme.primary.withValues(alpha: 0.1),
//                     blurRadius: 20,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: const Row(
//                 children: [
//                   Icon(Icons.search_rounded, color: AppTheme.primary, size: 22),
//                   SizedBox(width: 12),
//                   Text(
//                     'Search services...',
//                     style: TextStyle(color: AppTheme.textLight, fontSize: 14),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ── Promo Card ──────────────────────────────────────────────────────────────
//   Widget _buildPromoCard() {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
//       child: Container(
//         height: 148,
//         decoration: BoxDecoration(
//           gradient: AppTheme.cardGradient,
//           borderRadius: BorderRadius.circular(24),
//           boxShadow: [
//             BoxShadow(
//               color: AppTheme.primary.withValues(alpha: 0.3),
//               blurRadius: 24,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//         child: Stack(
//           children: [
//             Positioned(
//               right: -20,
//               top: -20,
//               child: Container(
//                 width: 180,
//                 height: 180,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: Colors.white.withValues(alpha: 0.08),
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(22),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withValues(alpha: 0.25),
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: const Text(
//                             '🎉 Special Offer',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 11,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         const Text(
//                           '30% OFF\nFirst Booking',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 12,
//                             fontWeight: FontWeight.w800,
//                             height: 1.2,
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         GestureDetector(
//                           onTap: () => Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => ServicesBrowseScreen(initialLocation: _selectedLocation),
//                             ),
//                           ),
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             child: const Text(
//                               'Browse Services →',
//                               style: TextStyle(
//                                 color: AppTheme.primary,
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w700,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const Text('🏠', style: TextStyle(fontSize: 64)),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── Categories ─────────────────────────────────────────────────────────────
//   Widget _buildCategories() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         SectionHeader(
//           title: 'Categories',
//           action: 'All',
//           onAction: () => Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => ServicesBrowseScreen(initialLocation: _selectedLocation),
//             ),
//           ),
//         ),
//         SizedBox(
//           height: 110,
//           child: ListView.builder(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             scrollDirection: Axis.horizontal,
//             itemCount: MockData.categories.length,
//             itemBuilder: (_, i) {
//               final cat = MockData.categories[i];
//               final color = Color(int.parse(cat.color.replaceFirst('#', '0xFF')));
//               return GestureDetector(
//                 onTap: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => ServicesBrowseScreen(
//                       initialCategory: cat.name,
//                       initialLocation: _selectedLocation,
//                     ),
//                   ),
//                 ),
//                 child: Container(
//                   width: 88,
//                   margin: const EdgeInsets.only(right: 10),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(18),
//                     boxShadow: [
//                       BoxShadow(
//                         color: color.withValues(alpha: 0.15),
//                         blurRadius: 12,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Container(
//                         width: 50,
//                         height: 50,
//                         decoration: BoxDecoration(
//                           color: color.withValues(alpha: 0.12),
//                           shape: BoxShape.circle,
//                         ),
//                         child: Center(
//                           child: Text(cat.icon, style: const TextStyle(fontSize: 24)),
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         cat.name,
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w600,
//                           color: AppTheme.textPrimary,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   // ── Latest Services — Filtered by Location ─────────────────────────────────
//   Widget _buildLatestServices() {
//     return StreamBuilder<List<ServiceListing>>(
//       stream: _firestore.getServiceListingsByLocation(_selectedLocation),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//             child: Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: AppTheme.error.withValues(alpha: 0.08),
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: Text(
//                       'Error: ${snapshot.error}',
//                       style: const TextStyle(color: AppTheme.error, fontSize: 13),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }

//         if (!snapshot.hasData) {
//           return const Padding(
//             padding: EdgeInsets.symmetric(vertical: 40),
//             child: Center(
//               child: CircularProgressIndicator(color: AppTheme.primary),
//             ),
//           );
//         }

//         final listings = snapshot.data!.take(10).toList();

//         if (listings.isEmpty) {
//           return Padding(
//             padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
//             child: Container(
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(18),
//                 border: Border.all(color: AppTheme.divider),
//               ),
//               child: Column(
//                 children: [
//                   const Text('📍', style: TextStyle(fontSize: 40)),
//                   const SizedBox(height: 12),
//                   Text(
//                     'No services in $_selectedLocation',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w600,
//                       fontSize: 15,
//                       color: AppTheme.textPrimary,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   const Text(
//                     'Try changing your location',
//                     style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
//                   ),
//                   const SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: _changeLocation,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppTheme.primary,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                     ),
//                     child: const Text('Change Location'),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }

//         return ListView.builder(
//           padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           itemCount: listings.length,
//           itemBuilder: (_, i) => _ServiceTile(listing: listings[i]),
//         );
//       },
//     );
//   }
// }

// // ── Service Tile ─────────────────────────────────────────────────────────────
// class _ServiceTile extends StatelessWidget {
//   final ServiceListing listing;
//   const _ServiceTile({required this.listing});

//   @override
//   Widget build(BuildContext context) {
//     final catData = MockData.categories.where((c) => c.name == listing.category).toList();
//     final catIcon = catData.isNotEmpty ? catData.first.icon : '🔧';
//     final catColor = catData.isNotEmpty
//         ? Color(int.parse(catData.first.color.replaceFirst('#', '0xFF')))
//         : AppTheme.primary;

//     return GestureDetector(
//       onTap: () => Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => ServiceListingDetailScreen(listing: listing),
//         ),
//       ),
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 12),
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(18),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.05),
//               blurRadius: 12,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             // Icon
//             Container(
//               width: 52,
//               height: 52,
//               decoration: BoxDecoration(
//                 color: catColor.withValues(alpha: 0.12),
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               child: Center(child: Text(catIcon, style: const TextStyle(fontSize: 26))),
//             ),
//             const SizedBox(width: 14),
//             // Info
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     listing.title,
//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w700,
//                       color: AppTheme.textPrimary,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 3),
//                   Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                         decoration: BoxDecoration(
//                           color: catColor.withValues(alpha: 0.1),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Text(
//                           listing.category,
//                           style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.w600),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       const Icon(Icons.location_on_outlined, size: 10, color: AppTheme.textLight),
//                       const SizedBox(width: 3),
//                       Expanded(
//                         child: Text(
//                           listing.providerLocation.isEmpty ? 'Location not specified' : listing.providerLocation,
//                           overflow: TextOverflow.ellipsis,
//                           style: const TextStyle(fontSize: 10, color: AppTheme.textLight),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 10),
//             // Price
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Text(
//                   '₹${listing.price.toInt()}',
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w800,
//                     color: AppTheme.primary,
//                   ),
//                 ),
//                 Text(
//                   listing.priceUnit,
//                   style: const TextStyle(fontSize: 9, color: AppTheme.textLight),
//                 ),
//                 const SizedBox(height: 6),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
//                   decoration: BoxDecoration(
//                     gradient: AppTheme.accentGradient,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: const Text(
//                     'Book',
//                     style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }