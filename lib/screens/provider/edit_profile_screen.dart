import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firebase_services.dart';
import '../../theme/app_theme.dart';

/// Lets a provider fill in optional contact details — email and a
/// business/contact address — that then show up on their public profile
/// for customers browsing their services. Nothing here is mandatory; a
/// provider can leave either field blank and save the rest.
class EditProfileScreen extends StatefulWidget {
  final AppUser user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.user.email);
    _addressCtrl = TextEditingController(
        text: widget.user.addresses.isNotEmpty
            ? widget.user.addresses.first
            : '');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    if (value.isEmpty) return true; // optional — empty is fine
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  Future<void> _save() async {
    final email = _emailCtrl.text.trim();
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email or leave it blank')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await AuthService().updateUserContactInfo(
        widget.user.uid,
        email: email,
        address: _addressCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Personal Information'),
        backgroundColor: AppTheme.primary,
        titleTextStyle: AppTheme.appBarTitleStyle(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'These details show up on your public profile so customers can reach you. All fields are optional.',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Phone Number',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.divider.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.call_outlined,
                      size: 18, color: AppTheme.textLight),
                  const SizedBox(width: 10),
                  Text(
                    widget.user.phone.isNotEmpty
                        ? widget.user.phone
                        : 'Not set',
                    style: const TextStyle(
                        fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  const Spacer(),
                  const Icon(Icons.lock_outline_rounded,
                      size: 14, color: AppTheme.textLight),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text('Linked to your login — can\'t be changed here',
                style: TextStyle(fontSize: 11.5, color: AppTheme.textLight)),

            const SizedBox(height: 22),

            const Text('Email (optional)',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'you@example.com',
                prefixIcon: const Icon(Icons.email_outlined,
                    color: AppTheme.textLight, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.divider),
                ),
              ),
            ),

            const SizedBox(height: 22),

            const Text('Business / Contact Address (optional)',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _addressCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Shop / office address customers can see',
                prefixIcon: const Icon(Icons.location_on_outlined,
                    color: AppTheme.textLight, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.divider),
                ),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Save Changes',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
