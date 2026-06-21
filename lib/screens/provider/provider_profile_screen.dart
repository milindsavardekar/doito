import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/models.dart';
import '../../services/firebase_services.dart';
import '../../theme/app_theme.dart';
//import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';
import '../services/manage_listings_screen.dart';
import '../services/add_edit_listing_screen.dart';
import 'edit_profile_screen.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  AppUser? _user;
  bool _loading = true;
  int _totalListings = 0;
  int _totalBookings = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => _loading = false); return; }
    final user = await AuthService().getUserData(uid);
    FirestoreService().getMyListings(uid).first.then((l) {
      if (mounted) setState(() => _totalListings = l.length);
    });
    FirestoreService().getProviderBookings(uid).first.then((b) {
      if (mounted) setState(() => _totalBookings = b.length);
    });
    if (mounted) setState(() { _user = user; _loading = false; });
  }

  void _signOut() async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.surface,
        body: Center(
            child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final name = _user?.name ?? 'Provider';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Avatar
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 16)
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            child: Text(
                              name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : 'P',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                              Icons.storefront_rounded,
                              color: Colors.white, size: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Service Provider',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 4),
                    Text(_user?.email ?? '',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 13)),
                    const SizedBox(height: 20),

                    // Stats
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                        children: [
                          _Stat('$_totalListings', 'Services'),
                          Container(
                              width: 1, height: 32,
                              color: AppTheme.divider),
                          _Stat('$_totalBookings', 'Bookings'),
                          Container(
                              width: 1, height: 32,
                              color: AppTheme.divider),
                          _Stat(
                              (_user?.rating ?? 0) > 0
                                  ? _user!.rating.toStringAsFixed(1)
                                  : '—',
                              'Rating'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Menu
            _Section(title: 'MY SERVICES', items: [
              _Item(
                icon: Icons.list_alt_rounded,
                label: 'Manage Listed Services',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const ManageListingsScreen())),
              ),
              _Item(
                icon: Icons.add_circle_outline_rounded,
                label: 'Add New Service',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const AddEditListingScreen())),
                badge: '+',
              ),
            ]),

            _Section(title: 'ACCOUNT', items: [
              _Item(
                  icon: Icons.person_outline_rounded,
                  label: 'Personal Information',
                  onTap: () async {
                    if (_user == null) return;
                    final updated = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EditProfileScreen(user: _user!)),
                    );
                    if (updated == true) _load();
                  }),
              _Item(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () {}),
              _Item(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () {}),
            ]),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded,
                    color: AppTheme.error),
                label: const Text('Sign Out',
                    style: TextStyle(
                        color: AppTheme.error,
                        fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: AppTheme.error),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat(this.value, this.label);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textLight)),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _Section({required this.title, required this.items});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 4),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppTheme.textLight, letterSpacing: 1.0)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12)
              ],
            ),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  const _Item(
      {required this.icon, required this.label,
      required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary)),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badge!,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            if (badge == null)
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textLight, size: 20),
          ],
        ),
      ),
    );
  }
}
