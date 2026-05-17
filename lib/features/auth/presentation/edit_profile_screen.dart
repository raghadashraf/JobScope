import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../auth/data/auth_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _headlineCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();

  Uint8List? _newImageBytes;
  bool _isSaving = false;
  String? _currentPhotoUrl;
  UserRole? _role;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideIn = Tween(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        _nameCtrl.text = user.name;
        _phoneCtrl.text = user.phone ?? '';
        _bioCtrl.text = user.bio ?? '';
        _headlineCtrl.text = user.headline ?? '';
        _locationCtrl.text = user.location ?? '';
        _linkedinCtrl.text = user.linkedinUrl ?? '';
        _websiteCtrl.text = user.website ?? '';
        _companyCtrl.text = user.company ?? '';
        setState(() {
          _currentPhotoUrl = user.photoUrl;
          _role = user.role;
        });
      }
      _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _headlineCtrl.dispose();
    _locationCtrl.dispose();
    _linkedinCtrl.dispose();
    _websiteCtrl.dispose();
    _companyCtrl.dispose();
    super.dispose();
  }

  Color get _accent =>
      _role == UserRole.recruiter ? AppColors.secondary : AppColors.primary;

  LinearGradient get _gradient => _role == UserRole.recruiter
      ? AppColors.secondaryGradient
      : AppColors.primaryGradient;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // ── Gradient header ──────────────────────────────────────────────
            ClipPath(
              clipper: _ArcClipper(),
              child: Container(
                decoration: BoxDecoration(gradient: _gradient),
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    height: 200,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25)),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded,
                                  size: 15, color: Colors.white),
                            ),
                          ),
                          const Spacer(),
                          // Avatar overlapping header
                          Center(
                            child: _AvatarSection(
                              imageBytes: _newImageBytes,
                              photoUrl: _currentPhotoUrl,
                              name: _nameCtrl.text,
                              onTap: _pickImage,
                              accent: _accent,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Form ─────────────────────────────────────────────────────────
            Expanded(
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideIn,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // change photo link
                          Center(
                            child: TextButton(
                              onPressed: _pickImage,
                              child: Text('Change Photo',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: _accent,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // ── Section: Basic Info ──────────────────────────
                          _sectionLabel('Basic Info'),
                          const SizedBox(height: 12),
                          _field(
                            controller: _nameCtrl,
                            label: 'Full Name',
                            hint: 'Your full name',
                            icon: Icons.person_outline_rounded,
                            action: TextInputAction.next,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            controller: _headlineCtrl,
                            label: 'Headline',
                            hint: _role == UserRole.recruiter
                                ? 'e.g. Senior Recruiter at Acme Corp'
                                : 'e.g. Flutter Developer | Open to work',
                            icon: Icons.badge_outlined,
                            action: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            controller: _bioCtrl,
                            label: 'Bio',
                            hint: 'Tell people about yourself…',
                            icon: Icons.notes_rounded,
                            maxLines: 4,
                            action: TextInputAction.newline,
                          ),
                          const SizedBox(height: 24),

                          // ── Section: Contact ─────────────────────────────
                          _sectionLabel('Contact'),
                          const SizedBox(height: 12),
                          _field(
                            controller: _phoneCtrl,
                            label: 'Phone Number',
                            hint: '+20 10 1234 5678',
                            icon: Icons.phone_outlined,
                            keyboard: TextInputType.phone,
                            action: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            controller: _locationCtrl,
                            label: 'Location',
                            hint: 'Cairo, Egypt',
                            icon: Icons.location_on_outlined,
                            action: TextInputAction.next,
                          ),
                          const SizedBox(height: 24),

                          // ── Section: Links ───────────────────────────────
                          _sectionLabel('Links'),
                          const SizedBox(height: 12),
                          _field(
                            controller: _linkedinCtrl,
                            label: 'LinkedIn URL',
                            hint: 'linkedin.com/in/yourname',
                            icon: Icons.link_rounded,
                            keyboard: TextInputType.url,
                            action: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            controller: _websiteCtrl,
                            label: 'Website / Portfolio',
                            hint: 'yourportfolio.com',
                            icon: Icons.language_rounded,
                            keyboard: TextInputType.url,
                            action: TextInputAction.next,
                          ),

                          if (_role == UserRole.recruiter) ...[
                            const SizedBox(height: 24),
                            _sectionLabel('Company'),
                            const SizedBox(height: 12),
                            _field(
                              controller: _companyCtrl,
                              label: 'Company Name',
                              hint: 'e.g. Acme Corporation',
                              icon: Icons.business_rounded,
                              action: TextInputAction.done,
                            ),
                          ],

                          const SizedBox(height: 36),

                          // ── Save button ──────────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: _gradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: _accent.withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: TextButton(
                                onPressed: _isSaving ? null : _save,
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white))
                                    : Text('Save Changes',
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        )),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboard,
    TextInputAction? action,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.3)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          textInputAction: action,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary),
            prefixIcon: maxLines == 1
                ? Padding(
                    padding: const EdgeInsets.all(13),
                    child: Icon(icon, size: 18, color: AppColors.textTertiary),
                  )
                : null,
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
              borderSide: BorderSide(color: _accent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 14 : 0,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _newImageBytes = bytes);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final firebaseUser = ref.read(firebaseUserProvider).value;
      if (firebaseUser == null) throw Exception('Not logged in');
      final repo = ref.read(authRepositoryProvider);

      String? photoUrl = _currentPhotoUrl;
      if (_newImageBytes != null) {
        photoUrl = await repo.uploadProfilePhoto(
          uid: firebaseUser.uid,
          imageBytes: _newImageBytes!,
        );
      }

      await repo.updateProfile(
        uid: firebaseUser.uid,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        photoUrl: photoUrl,
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        headline:
            _headlineCtrl.text.trim().isEmpty ? null : _headlineCtrl.text.trim(),
        location:
            _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        linkedinUrl:
            _linkedinCtrl.text.trim().isEmpty ? null : _linkedinCtrl.text.trim(),
        website:
            _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
        company:
            _companyCtrl.text.trim().isEmpty ? null : _companyCtrl.text.trim(),
      );

      ref.invalidate(currentUserProvider);
      if (mounted) {
        _showSnack('Profile updated!', isError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

// ── Avatar section widget ─────────────────────────────────────────────────────
class _AvatarSection extends StatelessWidget {
  final Uint8List? imageBytes;
  final String? photoUrl;
  final String name;
  final VoidCallback onTap;
  final Color accent;

  const _AvatarSection({
    required this.imageBytes,
    required this.photoUrl,
    required this.name,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: imageBytes != null
                  ? Image.memory(imageBytes!, fit: BoxFit.cover)
                  : (photoUrl != null && photoUrl!.isNotEmpty
                      ? Image.network(photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, _) => _fallback())
                      : _fallback()),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.3), width: 2),
              ),
              child: Icon(Icons.camera_alt_rounded, size: 14, color: accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() => Container(
        color: Colors.white.withValues(alpha: 0.2),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ),
      );
}

// ── Arc clipper ───────────────────────────────────────────────────────────────
class _ArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 36);
    path.quadraticBezierTo(
        size.width / 2, size.height + 18, size.width, size.height - 36);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
