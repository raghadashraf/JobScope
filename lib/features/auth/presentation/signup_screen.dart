import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_router.dart';
import '../../../data/models/user_model.dart';
import '../data/auth_providers.dart';
import 'widgets/auth_widgets.dart';

class SignupScreen extends ConsumerStatefulWidget {
  final String role;
  const SignupScreen({super.key, required this.role});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  bool get _isCandidate => widget.role == 'candidate';
  LinearGradient get _gradient =>
      _isCandidate ? AppColors.primaryGradient : AppColors.secondaryGradient;
  Color get _roleColor =>
      _isCandidate ? AppColors.primary : AppColors.secondary;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween(begin: const Offset(0, 0.12), end: Offset.zero).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please agree to the Terms & Privacy Policy'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final role = _isCandidate ? UserRole.candidate : UserRole.recruiter;
      final user = await ref.read(authRepositoryProvider).signUp(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
            role: role,
          );

      if (!mounted) return;

      // Push the correct user into the notifier immediately so the router
      // redirect fires with the right role before the Firebase stream rebuilds.
      ref.read(currentUserProvider.notifier).setUser(user);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Welcome to JobScope, ${user.name}! 🎉'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));

      if (context.mounted) {
        context.go(user.role == UserRole.candidate
            ? AppRoutes.candidateHome
            : AppRoutes.recruiterHome);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'email-already-in-use'   => 'An account with this email already exists',
        'weak-password'          => 'Password is too weak. Use at least 6 characters.',
        'invalid-email'          => 'Invalid email format',
        'network-request-failed' => 'Connection failed. Check your internet.',
        'channel-error'          => 'Connection error. Check your internet and try again.',
        _                        => 'Sign up failed. Please try again.',
      };
      _showError(msg);
    } catch (e) {
      if (mounted) _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final heroHeight = size.height * 0.36;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _roleColor,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // ── Gradient hero ──────────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: heroHeight,
              child: AuthHeroBg(gradient: _gradient, roleColor: _roleColor),
            ),

            SingleChildScrollView(
              child: Column(
                children: [
                  // Header area
                  SizedBox(
                    height: heroHeight,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha: 0.25)),
                                ),
                                child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 16,
                                    color: Colors.white),
                              ),
                            ),
                            const Spacer(),

                            // App logo
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Image.asset('assets/images/logo.png',
                                  fit: BoxFit.contain),
                            ),
                            const SizedBox(height: 12),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _isCandidate
                                    ? 'Candidate Sign Up'
                                    : 'Recruiter Sign Up',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Colors.white.withValues(alpha: 0.95),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Create account',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -1.2,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Join thousands of professionals on JobScope',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Form card ──────────────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Container(
                        constraints:
                            BoxConstraints(minHeight: size.height - heroHeight),
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                        ),
                        padding:
                            const EdgeInsets.fromLTRB(24, 32, 24, 32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('Full name'),
                              const SizedBox(height: 8),
                              _inputField(
                                controller: _nameCtrl,
                                hint: 'Your full name',
                                icon: Icons.person_outline_rounded,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Name is required'
                                        : null,
                              ),
                              const SizedBox(height: 18),
                              _sectionLabel('Email address'),
                              const SizedBox(height: 8),
                              _inputField(
                                controller: _emailCtrl,
                                hint: 'name@company.com',
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Email is required';
                                  }
                                  if (!v.contains('@')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              _sectionLabel('Password'),
                              const SizedBox(height: 8),
                              _inputField(
                                controller: _passCtrl,
                                hint: 'At least 6 characters',
                                icon: Icons.lock_outline_rounded,
                                obscure: _obscure,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    size: 20,
                                    color: AppColors.textTertiary,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (v.length < 6) {
                                    return 'Minimum 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Terms checkbox
                              GestureDetector(
                                onTap: () => setState(
                                    () => _agreeToTerms = !_agreeToTerms),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                  children: [
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: _agreeToTerms
                                            ? _roleColor
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(7),
                                        border: Border.all(
                                          color: _agreeToTerms
                                              ? _roleColor
                                              : AppColors.borderDark,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: _agreeToTerms
                                          ? const Icon(Icons.check_rounded,
                                              size: 14, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text.rich(
                                        TextSpan(
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                            height: 1.5,
                                          ),
                                          children: [
                                            const TextSpan(
                                                text: 'I agree to the '),
                                            TextSpan(
                                              text: 'Terms of Service',
                                              style: TextStyle(
                                                  color: _roleColor,
                                                  fontWeight:
                                                      FontWeight.w600),
                                            ),
                                            const TextSpan(text: ' and '),
                                            TextSpan(
                                              text: 'Privacy Policy',
                                              style: TextStyle(
                                                  color: _roleColor,
                                                  fontWeight:
                                                      FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),

                              AuthPrimaryButton(
                                label: 'Create Account',
                                gradient: _gradient,
                                roleColor: _roleColor,
                                isLoading: _isLoading,
                                onTap: _handleSignup,
                              ),
                              const SizedBox(height: 24),

                              Center(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                      foregroundColor: _roleColor),
                                  child: Text.rich(
                                    TextSpan(children: [
                                      TextSpan(
                                        text: 'Already have an account?  ',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Sign In',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _roleColor,
                                        ),
                                      ),
                                    ]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0.1,
        ),
      );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(13),
          child: Icon(icon, size: 20, color: AppColors.textTertiary),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _roleColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      validator: validator,
    );
  }
}
