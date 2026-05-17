import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/app_router.dart';

// ─── Dark palette used only on this screen ────────────────────────────────────
const _bg = Color(0xFF060E1E);
const _bgMid = Color(0xFF0A1628);
const _glassColor = Color(0xFFFFFFFF);
const _accentBlue = Color(0xFF4D8EFF);
const _accentTeal = Color(0xFF2DD4BF);
const _accentGold = Color(0xFFFFD166);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Logo
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  // Title + tagline
  late final Animation<double> _headingOpacity;
  late final Animation<Offset> _headingSlide;
  late final Animation<double> _taglineOpacity;

  // Features
  late final List<Animation<double>> _featureOpacity;
  late final List<Animation<Offset>> _featureSlide;

  // Buttons
  late final Animation<double> _buttonsOpacity;
  late final Animation<Offset> _buttonsSlide;

  static const _dur = Duration(milliseconds: 1800);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _dur);

    Animation<double> interval(double start, double end, {Curve curve = Curves.easeOut}) =>
        CurvedAnimation(parent: _ctrl, curve: Interval(start, end, curve: curve));

    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(interval(0.0, 0.25));
    _logoScale = Tween(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.35, curve: Curves.elasticOut)));

    _headingOpacity = Tween(begin: 0.0, end: 1.0).animate(interval(0.20, 0.45));
    _headingSlide = Tween(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(interval(0.20, 0.45));

    _taglineOpacity = Tween(begin: 0.0, end: 1.0).animate(interval(0.32, 0.55));

    final featureIntervals = [
      (0.48, 0.66),
      (0.57, 0.74),
      (0.66, 0.82),
    ];
    _featureOpacity = featureIntervals
        .map((i) => Tween(begin: 0.0, end: 1.0).animate(interval(i.$1, i.$2)))
        .toList();
    _featureSlide = featureIntervals
        .map((i) => Tween(begin: const Offset(0.25, 0), end: Offset.zero)
            .animate(interval(i.$1, i.$2)))
        .toList();

    _buttonsOpacity = Tween(begin: 0.0, end: 1.0).animate(interval(0.78, 1.0));
    _buttonsSlide = Tween(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(interval(0.78, 1.0));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            // ── Gradient background ──────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_bg, _bgMid, Color(0xFF0D1F3A)],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // ── Glow blobs ───────────────────────────────────────────────────
            const Positioned(
              top: -80,
              right: -60,
              child: _GlowBlob(size: 280, color: Color(0xFF0A66C2), opacity: 0.18),
            ),
            const Positioned(
              bottom: 60,
              left: -80,
              child: _GlowBlob(size: 240, color: Color(0xFF0D9488), opacity: 0.14),
            ),
            Positioned(
              top: h * 0.42,
              right: -50,
              child: const _GlowBlob(size: 180, color: Color(0xFF6366F1), opacity: 0.10),
            ),

            // ── Content ───────────────────────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    SizedBox(height: h * 0.06),

                    // Logo
                    FadeTransition(
                      opacity: _logoOpacity,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: const _LogoBadge(),
                      ),
                    ),
                    SizedBox(height: h * 0.028),

                    // Title + tagline
                    FadeTransition(
                      opacity: _headingOpacity,
                      child: SlideTransition(
                        position: _headingSlide,
                        child: Text(
                          'JobScope',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 54,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -2.8,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeTransition(
                      opacity: _taglineOpacity,
                      child: Text(
                        'Your career, powered by AI',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.48),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Feature glass card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                      decoration: BoxDecoration(
                        color: _glassColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: _glassColor.withValues(alpha: 0.09),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _animatedFeature(
                            index: 0,
                            icon: Icons.auto_awesome_rounded,
                            iconColor: _accentBlue,
                            title: 'AI-Powered Matching',
                            subtitle: 'Jobs that actually fit your skills, instantly',
                          ),
                          const _FeatureDivider(),
                          _animatedFeature(
                            index: 1,
                            icon: Icons.description_rounded,
                            iconColor: _accentTeal,
                            title: 'Smart CV Analysis',
                            subtitle: 'Upload once — our AI parses everything for you',
                          ),
                          const _FeatureDivider(),
                          _animatedFeature(
                            index: 2,
                            icon: Icons.rocket_launch_rounded,
                            iconColor: _accentGold,
                            title: 'Fast-Track Hiring',
                            subtitle: 'Recruiters discover top talent in seconds',
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // CTA buttons
                    FadeTransition(
                      opacity: _buttonsOpacity,
                      child: SlideTransition(
                        position: _buttonsSlide,
                        child: Column(
                          children: [
                            // Primary CTA
                            SizedBox(
                              height: 56,
                              width: double.infinity,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF1D70F0), Color(0xFF0A4FBB)],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1D70F0).withValues(alpha: 0.45),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: TextButton(
                                  onPressed: () =>
                                      context.push(AppRoutes.roleSelection),
                                  style: TextButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18)),
                                  ),
                                  child: Text(
                                    'Get Started',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Sign In link
                            TextButton(
                              onPressed: () =>
                                  context.push(AppRoutes.roleSelection),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text.rich(
                                TextSpan(children: [
                                  TextSpan(
                                    text: 'Already have an account?  ',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.white.withValues(alpha: 0.42),
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Sign In',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _accentBlue,
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _animatedFeature({
    required int index,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return FadeTransition(
      opacity: _featureOpacity[index],
      child: SlideTransition(
        position: _featureSlide[index],
        child: _FeatureRow(
          icon: icon,
          iconColor: iconColor,
          title: title,
          subtitle: subtitle,
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _GlowBlob({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: opacity * 1.5),
            blurRadius: size * 0.9,
            spreadRadius: size * 0.25,
          ),
        ],
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFF0A66C2).withValues(alpha: 0.25),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF1D70F0), Color(0xFF0A4FBB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: const Icon(Icons.work_rounded, size: 44, color: Colors.white),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  const _FeatureRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.45),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureDivider extends StatelessWidget {
  const _FeatureDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: 1,
      color: Colors.white.withValues(alpha: 0.07),
    );
  }
}
