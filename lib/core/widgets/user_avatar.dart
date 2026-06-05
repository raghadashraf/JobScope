import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/data/profile_photo_providers.dart';

class UserAvatar extends ConsumerWidget {
  final String uid;
  final String name;
  final String? photoUrl;
  final Uint8List? memoryBytes;
  final double size;
  final Color fallbackColor;
  final Color fallbackTextColor;

  const UserAvatar({
    super.key,
    required this.uid,
    required this.name,
    this.photoUrl,
    this.memoryBytes,
    this.size = 88,
    this.fallbackColor = const Color(0x40FFFFFF),
    this.fallbackTextColor = Colors.white,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (memoryBytes != null) {
      return _frame(child: Image.memory(memoryBytes!, fit: BoxFit.cover));
    }

    final sessionBytes = ref.watch(profilePhotoLocalCacheProvider)[uid];
    if (sessionBytes != null && sessionBytes.isNotEmpty) {
      return _frame(child: Image.memory(sessionBytes, fit: BoxFit.cover));
    }

    final persistedBytes = ref.watch(profilePhotoPersistedBytesProvider(uid));
    return persistedBytes.when(
      data: (bytes) {
        if (bytes != null && bytes.isNotEmpty) {
          return _frame(child: Image.memory(bytes, fit: BoxFit.cover));
        }
        return _loadFromStorageOrNetwork(ref);
      },
      loading: () => _loadFromStorageOrNetwork(ref),
      error: (_, _) => _loadFromStorageOrNetwork(ref),
    );
  }

  Widget _loadFromStorageOrNetwork(WidgetRef ref) {
    final storageBytes = ref.watch(profilePhotoBytesProvider(uid));
    return storageBytes.when(
      data: (bytes) {
        if (bytes != null && bytes.isNotEmpty) {
          return _frame(child: Image.memory(bytes, fit: BoxFit.cover));
        }
        return _networkOrFallback();
      },
      loading: () => _networkOrFallback(),
      error: (_, _) => _networkOrFallback(),
    );
  }

  Widget _networkOrFallback() {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return _frame(
        child: Image.network(
          photoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(),
        ),
      );
    }
    return _frame(child: _fallback());
  }

  Widget _frame({required Widget child}) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(child: child),
    );
  }

  Widget _fallback() => Container(
        color: fallbackColor,
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: size * 0.36,
              fontWeight: FontWeight.w800,
              color: fallbackTextColor,
            ),
          ),
        ),
      );
}
