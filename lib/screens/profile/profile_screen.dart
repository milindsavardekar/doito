import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/models.dart';
import '../../services/firebase_services.dart';
import '../../theme/app_theme.dart';
//import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';
import '../services/manage_listings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _user;
  bool _loading = true;
  int _totalBookings = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    final user = await AuthService().getUserData(uid);
    // Count bookings
    FirestoreService().getUserBookings(uid).first.then((bookings) {
      if (mounted) setState(() => _totalBookings = bookings.length);
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
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final name = _user?.name ?? 'User';
    final email = _user?.email ?? '';
    final phone = _user?.phone ?? '';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with gradient
            Container(
              decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
              child: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -30, right: -30,
                      child: Container(
                        width: 160, height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20, left: -40,
                      child: Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accent.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        const SizedBox(height: 24),
                        // Avatar
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 16)
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 44,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
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
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppTheme.primary, width: 2),
                              ),
                              child: const Icon(Icons.edit_rounded,
                                  color: AppTheme.primary, size: 14),
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
                        Text(email,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(phone,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ],
                        const SizedBox(height: 20),

                        // Stats card
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
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _ProfileStat(
                                  value: '$_totalBookings', label: 'Bookings'),
                              if (_user?.isServiceProvider == true) ...[
                                const _StatDivider(),
                                const _ProfileStat(
                                    value: '4.8', label: 'Avg Rating'),
                              ],
                              const _StatDivider(),
                              _ProfileStat(
                                value:
                                    _user?.addresses.isNotEmpty == true ? '${_user!.addresses.length}' : '0',
                                label: 'Addresses',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Menu sections
            _MenuSection(
              title: 'ACCOUNT',
              items: [
                _MenuItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Personal Information',
                    onTap: () {}),
                _MenuItem(
                    icon: Icons.location_on_outlined,
                    label: 'Saved Addresses',
                    onTap: () {}),
                _MenuItem(
                    icon: Icons.payment_outlined,
                    label: 'Payment Methods',
                    onTap: () {}),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () {},
                  trailing: Switch(
                    value: true,
                    onChanged: (_) {},
                    activeThumbColor: AppTheme.primary,
                  ),
                ),
              ],
            ),

            _MenuSection(
              title: 'SERVICES',
              items: [
                if (_user?.isServiceProvider == true)
                  _MenuItem(
                    icon: Icons.home_repair_service_rounded,
                    label: 'My Listed Services',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ManageListingsScreen()),
                    ),
                    badge: 'Provider',
                  ),
                _MenuItem(
                    icon: Icons.history_rounded,
                    label: 'Booking History',
                    onTap: () {}),
                _MenuItem(
                    icon: Icons.favorite_outline_rounded,
                    label: 'Saved Providers',
                    onTap: () {}),
                _MenuItem(
                    icon: Icons.star_outline_rounded,
                    label: 'My Reviews',
                    onTap: () {}),
                _MenuItem(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Refer & Earn',
                  onTap: () {},
                  badge: 'New',
                ),
              ],
            ),

            _MenuSection(
              title: 'SUPPORT',
              items: [
                _MenuItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () {}),
                _MenuItem(
                    icon: Icons.policy_outlined,
                    label: 'Privacy Policy',
                    onTap: () {}),
                _MenuItem(
                    icon: Icons.description_outlined,
                    label: 'Terms of Service',
                    onTap: () {}),
                _MenuItem(
                    icon: Icons.info_outline_rounded,
                    label: 'About Doito v1.0.0',
                    onTap: () {}),
              ],
            ),

            // Sign out button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
                label: const Text('Sign Out',
                    style: TextStyle(
                        color: AppTheme.error, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: AppTheme.error),
                  foregroundColor: AppTheme.error,
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

class _ProfileStat extends StatelessWidget {
  final String value, label;
  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppTheme.divider);
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _MenuSection({required this.title, required this.items});

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
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textLight,
                    letterSpacing: 1.0)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)
              ],
            ),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final String? badge;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.badge,
  });

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
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
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
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ?trailing,
            if (trailing == null && badge == null)
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textLight, size: 20),
          ],
        ),
      ),
    );
  }
}
