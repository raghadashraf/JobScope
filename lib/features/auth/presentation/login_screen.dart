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

class LoginScreen extends ConsumerStatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
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
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = await ref.read(authRepositoryProvider).signIn(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
          );

      if (!mounted) return;

      final expected = _isCandidate ? UserRole.candidate : UserRole.recruiter;
      if (user.role != expected) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'This account is registered as ${user.role.name}. Please use the correct login.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        await ref.read(authRepositoryProvider).signOut();
        setState(() => _isLoading = false);
        return;
      }

      if (context.mounted) {
        context.go(user.role == UserRole.candidate
            ? AppRoutes.candidateHome
            : AppRoutes.recruiterHome);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'user-not-found' => 'No account found with this email',
        'wrong-password' || 'invalid-credential' =>
          'Incorrect email or password',
        'invalid-email' => 'Invalid email format',
        _ => 'Sign in failed. Please try again.',
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
    final topPad = MediaQuery.of(context).padding.top;
    final heroHeight = size.height * 0.42;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _roleColor,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // ── Gradient hero ──────────────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0, height: heroHeight,
              child: AuthHeroBg(gradient: _gradient, roleColor: _roleColor),
            ),

            // ── Scrollable content ─────────────────────────────────────────
            SingleChildScrollView(
              child: Column(
                children: [
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
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25)),
                                ),
                                child: const Icon(Icons.arrow_back_ios_new_rounded,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 64, height: 64,
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
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _isCandidate ? 'Candidate Login' : 'Recruiter Login',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.95),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Welcome back',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 34, fontWeight: FontWeight.w800,
                                color: Colors.white, letterSpacing: -1.2, height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Sign in to continue your journey',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.7)),
                            ),
                            const SizedBox(height: 32),
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
                        constraints: BoxConstraints(
                            minHeight: size.height - heroHeight + topPad),
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Email address'),
                              const SizedBox(height: 8),
                              _field(
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
                              const SizedBox(height: 20),
                              _label('Password'),
                              const SizedBox(height: 8),
                              _field(
                                controller: _passCtrl,
                                hint: 'Enter your password',
                                icon: Icons.lock_outline_rounded,
                                obscure: _obscure,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    size: 20, color: AppColors.textTertiary,
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
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    foregroundColor: _roleColor,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 8),
                                  ),
                                  child: Text('Forgot password?',
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: _roleColor)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              AuthPrimaryButton(
                                label: 'Sign In',
                                gradient: _gradient,
                                roleColor: _roleColor,
                                isLoading: _isLoading,
                                onTap: _handleLogin,
                              ),
                              const SizedBox(height: 28),
                              _orDivider(),
                              const SizedBox(height: 24),
                              Center(
                                child: Text(
                                  "Don't have an account?",
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: AppColors.textSecondary),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 52,
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => context.push(
                                      AppRoutes.register, extra: widget.role),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: _roleColor, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    foregroundColor: _roleColor,
                                  ),
                                  child: Text('Create Account',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _roleColor,
                                      )),
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

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0.1,
        ),
      );

  Widget _field({
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

  Widget _orDivider() => Row(
        children: [
          Expanded(child: Divider(color: AppColors.border, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('or',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textTertiary)),
          ),
          Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        ],
      );
}
