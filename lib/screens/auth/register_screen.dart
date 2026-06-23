import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../home/main_screen.dart';
import '../provider/provider_main_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  
  bool _loading = false;
  bool _agreeTerms = false;
  String _selectedRole = 'user';
  
  // OTP states
  bool _isOtpSent = false;
  String _verificationId = '';
  int _resendTimer = 0;
  bool _isResendEnabled = false;

  final _auth = AuthService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _sendOTP() async {
    if (_phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter phone number')),
      );
      return;
    }
    if (normalizeMobile(_phoneCtrl.text).length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-digit phone number')),
      );
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _auth.sendOTP(
        phoneNumber: toE164(_phoneCtrl.text),
        onVerificationCompleted: (credential) async {
          if (credential != null) {
            await _verifyOTPAndRegister(credential);
          }
        },
        onCodeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _isOtpSent = true;
            _loading = false;
            _resendTimer = 30;
            _isResendEnabled = false;
          });
          _startResendTimer();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('OTP sent successfully!')),
            );
          }
        },
        onError: (error) {
          if (!mounted) return;
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send OTP: $error')),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (_resendTimer > 0) {
            _resendTimer--;
            _startResendTimer();
          } else {
            _isResendEnabled = true;
          }
        });
      }
    });
  }

  void _resendOTP() {
    if (_isResendEnabled) {
      _sendOTP();
    }
  }

  Future<void> _verifyOTPAndRegister([PhoneAuthCredential? credential]) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to Terms & Conditions')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      UserCredential? userCredential;

      if (credential != null) {
        userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      } else if (_otpCtrl.text.isNotEmpty && _verificationId.isNotEmpty) {
        final smsCode = _otpCtrl.text.trim();
        final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId,
          smsCode: smsCode,
        );
        userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      } else {
        throw Exception('Please enter OTP');
      }

      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(_nameCtrl.text.trim());

        // Check first: does this phone already have an account (current
        // uid, or an older uid from before OTP login existed)? If so,
        // reuse it (and its real role) instead of creating a duplicate.
        final existing = await _auth.resolveUserForLogin(
          uid: user.uid,
          phone: _phoneCtrl.text.trim(),
        );

        // Always use what the user selected — don't inherit old role
        final effectiveRole = _selectedRole;

        if (existing?.isBlocked == true) {
          await _auth.signOut();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Your account has been blocked. Contact support for help.'),
            ),
          );
          setState(() => _loading = false);
          return;
        }

        if (existing == null) {
          await _auth.saveUserDataWithOTP(
            uid: user.uid,
            name: _nameCtrl.text.trim(),
            email: '',
            phone: _phoneCtrl.text.trim(),
            role: _selectedRole,
          );
        } else {
          // Account exists — update role to what user selected now
          await _auth.updateUserRole(uid: user.uid, role: _selectedRole);
        }

        if (mounted) {
          if (existing != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Account already exists — logging you in')),
            );
          }
          if (!mounted) return;
          if (effectiveRole == 'service_provider') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const ProviderMainScreen(),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const MainScreen(initialIndex: 0),
              ),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Verification failed')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProvider = _selectedRole == 'service_provider';
    
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header gradient
              Container(
                decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Create Account',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Join Doito today',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 24),

                    // Role Selector
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _RoleTab(
                            icon: Icons.person_rounded,
                            label: 'Customer',
                            subtitle: 'Book services',
                            isSelected: _selectedRole == 'user',
                            onTap: () => setState(() => _selectedRole = 'user'),
                          ),
                          _RoleTab(
                            icon: Icons.home_repair_service_rounded,
                            label: 'Provider',
                            subtitle: 'Offer services',
                            isSelected: isProvider,
                            onTap: () => setState(
                                () => _selectedRole = 'service_provider'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Role info banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: isProvider
                    ? AppTheme.accent.withValues(alpha: 0.08)
                    : AppTheme.primary.withValues(alpha: 0.06),
                child: Row(
                  children: [
                    Icon(
                      isProvider
                          ? Icons.storefront_rounded
                          : Icons.shopping_bag_outlined,
                      color: isProvider ? AppTheme.accent : AppTheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isProvider
                            ? 'List your services, manage bookings & grow your business'
                            : 'Search & book trusted home service professionals',
                        style: TextStyle(
                          fontSize: 12,
                          color: isProvider ? AppTheme.accent : AppTheme.primary,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Name
                      AppTextField(
                        label: 'Full Name',
                        hint: isProvider
                            ? 'Your name / business name'
                            : 'Rahul Sharma',
                        controller: _nameCtrl,
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'Enter your name'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Phone with OTP
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: AppTextField(
                              label: 'Phone Number',
                              hint: '+91 98765 43210',
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              prefixIcon: Icons.phone_outlined,
                              validator: (v) => (v?.trim().isEmpty ?? true)
                                  ? 'Enter phone number'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Verify',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 52,
                                  child: GradientButton(
                                    label: _isOtpSent ? 'Resend' : 'Send OTP',
                                    onTap: _isOtpSent ? _resendOTP : _sendOTP,
                                    isLoading: _loading && !_isOtpSent,
                                  ),
                                ),
                                if (_isOtpSent && _resendTimer > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Resend in ${_resendTimer}s',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textLight,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_isOtpSent) ...[
                        AppTextField(
                          label: 'Enter OTP',
                          hint: '6-digit code',
                          controller: _otpCtrl,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.verified_outlined,
                          validator: (v) =>
                              (v?.length ?? 0) < 6 ? 'Enter 6-digit OTP' : null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Terms & Conditions
                      Row(
                        children: [
                          SizedBox(
                            width: 22, height: 22,
                            child: Checkbox(
                              value: _agreeTerms,
                              activeColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
                              onChanged: (v) =>
                                  setState(() => _agreeTerms = v ?? false),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: 'I agree to the ',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary),
                                children: [
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Register Button
                      GradientButton(
                        label: _isOtpSent
                            ? (isProvider
                                ? 'Verify & Create Provider Account'
                                : 'Verify & Create Account')
                            : (isProvider
                                ? 'Continue with Phone'
                                : 'Continue with Phone'),
                        onTap: () {
                          if (_isOtpSent) {
                            _verifyOTPAndRegister(null);
                          } else {
                            _sendOTP();
                          }
                        },
                        isLoading: _loading,
                        icon: _isOtpSent
                            ? Icons.verified_rounded
                            : Icons.phone_android_rounded,
                      ),
                      const SizedBox(height: 20),

                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account? ',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14)),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            ),
                            child: const Text('Sign In',
                                style: TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Role Tab Widget ──
class _RoleTab extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleTab({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2))]
                : [],
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? AppTheme.primary : Colors.white70,
                  size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: isSelected ? AppTheme.primary : Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              Text(subtitle,
                  style: TextStyle(
                      color: isSelected ? AppTheme.textSecondary : Colors.white54,
                      fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}