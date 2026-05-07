import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../data/auth_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  Uint8List? _selectedImageBytes;
  String? _currentPhotoUrl;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.user.name);

    _phoneController = TextEditingController(text: widget.user.phone ?? '');

    _currentPhotoUrl = widget.user.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();

      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      setState(() {
        _selectedImageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      _showSnackBar('Failed to pick image: $e', isError: true);
    }
  }

  Future<void> _showImageSourceSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Change Profile Photo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 20),

              _imageSourceOption(
                icon: Icons.photo_library_rounded,
                label: 'Choose from Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),

              const SizedBox(height: 12),

              if (_selectedImageBytes != null || _currentPhotoUrl != null)
                _imageSourceOption(
                  icon: Icons.delete_outline_rounded,
                  label: 'Remove Photo',
                  color: AppColors.error,
                  onTap: () {
                    Navigator.pop(context);

                    setState(() {
                      _selectedImageBytes = null;
                      _currentPhotoUrl = null;
                    });
                  },
                ),

              const SizedBox(height: 12),

              _imageSourceOption(
                icon: Icons.close_rounded,
                label: 'Cancel',
                onTap: () => Navigator.pop(context),
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _imageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: color ?? AppColors.textPrimary, size: 22),

              const SizedBox(width: 16),

              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? photoUrl = _currentPhotoUrl;

      // Upload new image
      if (_selectedImageBytes != null) {
        photoUrl = await ref
            .read(authRepositoryProvider)
            .uploadProfilePhoto(
              uid: widget.user.uid,
              imageBytes: _selectedImageBytes!,
            );
      }

      // Update user profile
      await ref
          .read(authRepositoryProvider)
          .updateProfile(
            uid: widget.user.uid,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            photoUrl: photoUrl,
          );

      // Refresh user provider
      ref.invalidate(currentUserProvider);

      if (!mounted) return;

      _showSnackBar('Profile updated successfully! 🎉');

      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;

      _showSnackBar('Failed to update profile: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // Profile Photo
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,

                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,

                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),

                        child: ClipOval(
                          child: _selectedImageBytes != null
                              ? Image.memory(
                                  _selectedImageBytes!,
                                  fit: BoxFit.cover,
                                )
                              : _currentPhotoUrl != null
                              ? Image.network(
                                  _currentPhotoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => _buildInitial(),
                                )
                              : _buildInitial(),
                        ),
                      ),

                      Positioned(
                        bottom: 0,
                        right: 0,

                        child: Material(
                          color: Colors.transparent,

                          child: InkWell(
                            onTap: _showImageSourceSheet,
                            borderRadius: BorderRadius.circular(20),

                            child: Container(
                              width: 40,
                              height: 40,

                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 3,
                                ),
                              ),

                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: TextButton.icon(
                    onPressed: _showImageSourceSheet,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Change Photo'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Email
                _buildSection(
                  title: 'Email',

                  child: Container(
                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),

                    child: Row(
                      children: [
                        const Icon(
                          Icons.mail_outline_rounded,
                          size: 20,
                          color: AppColors.textTertiary,
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            widget.user.email,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),

                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),

                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: AppColors.success,
                              ),

                              const SizedBox(width: 4),

                              Text(
                                'Verified',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Full Name
                _buildSection(
                  title: 'Full Name',

                  child: TextFormField(
                    controller: _nameController,

                    style: GoogleFonts.inter(fontSize: 14),

                    decoration: const InputDecoration(
                      hintText: 'Enter your full name',

                      prefixIcon: Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.person_outline_rounded, size: 20),
                      ),
                    ),

                    textCapitalization: TextCapitalization.words,

                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Name is required';
                      }

                      if (v.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }

                      if (v.trim().length > 50) {
                        return 'Name is too long';
                      }

                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Phone Number
                _buildSection(
                  title: 'Phone Number',
                  optional: true,

                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,

                    style: GoogleFonts.inter(fontSize: 14),

                    decoration: const InputDecoration(
                      hintText: '+20 100 123 4567',

                      prefixIcon: Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.phone_outlined, size: 20),
                      ),
                    ),

                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return null;
                      }

                      final phoneRegex = RegExp(r'^[\+]?[0-9\s\-\(\)]{7,20}$');

                      if (!phoneRegex.hasMatch(v.trim())) {
                        return 'Enter a valid phone number';
                      }

                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Account Type
                _buildSection(
                  title: 'Account Type',

                  child: Container(
                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),

                    child: Row(
                      children: [
                        Icon(
                          widget.user.role == UserRole.candidate
                              ? Icons.person_search_rounded
                              : Icons.business_center_rounded,

                          size: 20,

                          color: widget.user.role == UserRole.candidate
                              ? AppColors.primary
                              : AppColors.secondary,
                        ),

                        const SizedBox(width: 12),

                        Text(
                          widget.user.role == UserRole.candidate
                              ? 'Candidate'
                              : 'Recruiter',

                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const Spacer(),

                        Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Save Button
                SizedBox(
                  height: 52,

                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,

                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.6,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,

                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [
                              const Icon(Icons.check_rounded, size: 20),

                              const SizedBox(width: 8),

                              Text(
                                'Save Changes',

                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                // Cancel Button
                SizedBox(
                  height: 52,

                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),

                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.border,
                        width: 1.5,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    child: Text(
                      'Cancel',

                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitial() {
    return Center(
      child: Text(
        widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'U',

        style: GoogleFonts.plusJakartaSans(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    bool optional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            Text(
              title,

              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            if (optional) ...[
              const SizedBox(width: 6),

              Text(
                '(Optional)',

                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 8),

        child,
      ],
    );
  }
}
