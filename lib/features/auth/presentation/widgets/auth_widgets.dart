import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Decorative gradient hero background ───────────────────────────────────────
class AuthHeroBg extends StatelessWidget {
  final LinearGradient gradient;
  final Color roleColor;
  const AuthHeroBg({super.key, required this.gradient, required this.roleColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          // Large glow top-right
          Positioned(
            top: -40,
            right: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          // Medium glow bottom-left
          Positioned(
            bottom: -20,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Small accent circle mid-left
          Positioned(
            top: 90,
            left: 30,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          // Diagonal stripe pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _DiagonalStripePainter(
                  color: Colors.white.withValues(alpha: 0.045)),
            ),
          ),
          // Ring outline top-right
          Positioned(
            top: 30,
            right: 30,
            child: CustomPaint(
              size: const Size(100, 100),
              painter: _RingPainter(color: Colors.white.withValues(alpha: 0.12)),
            ),
          ),
          // Ring outline bottom-left
          Positioned(
            bottom: 40,
            left: -20,
            child: CustomPaint(
              size: const Size(70, 70),
              painter: _RingPainter(color: Colors.white.withValues(alpha: 0.09)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color color;
  const _RingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width / 2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiagonalStripePainter extends CustomPainter {
  final Color color;
  const _DiagonalStripePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    const gap = 32.0;
    for (double i = -size.height; i < size.width + size.height; i += gap) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Reusable gradient primary button ─────────────────────────────────────────
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final LinearGradient gradient;
  final Color roleColor;
  final bool isLoading;
  final VoidCallback onTap;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.gradient,
    required this.roleColor,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: roleColor.withValues(alpha: isLoading ? 0.20 : 0.38),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TextButton(
          onPressed: isLoading ? null : onTap,
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
