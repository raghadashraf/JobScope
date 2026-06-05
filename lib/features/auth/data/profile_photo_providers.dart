import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_photo_storage.dart';

/// In-memory bytes shown immediately after pick/upload (same session only).
class ProfilePhotoLocalCache extends Notifier<Map<String, Uint8List>> {
  @override
  Map<String, Uint8List> build() => {};

  void cache(String uid, Uint8List bytes) {
    state = Map<String, Uint8List>.from(state)..[uid] = bytes;
  }
}

final profilePhotoLocalCacheProvider =
    NotifierProvider<ProfilePhotoLocalCache, Map<String, Uint8List>>(
        ProfilePhotoLocalCache.new);

/// Bytes persisted in localStorage — survives Chrome reload.
final profilePhotoPersistedBytesProvider =
    FutureProvider.family<Uint8List?, String>((ref, uid) async {
  return ProfilePhotoStorage.load(uid);
});

/// Loads profile photo bytes from Firebase Storage (fallback).
final profilePhotoBytesProvider =
    FutureProvider.family<Uint8List?, String>((ref, uid) async {
  User? firebaseUser;
  for (var wait = 0; wait < 6; wait++) {
    firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && firebaseUser.uid == uid) break;
    await Future.delayed(Duration(milliseconds: 300 * (wait + 1)));
  }
  if (firebaseUser == null || firebaseUser.uid != uid) return null;

  for (var attempt = 0; attempt < 4; attempt++) {
    try {
      await firebaseUser.getIdToken(attempt > 0);
      final storageRef =
          FirebaseStorage.instance.ref().child('profile_photos/$uid.jpg');
      final bytes = await storageRef.getData(2 * 1024 * 1024);
      if (bytes != null && bytes.isNotEmpty) {
        await ProfilePhotoStorage.save(uid, bytes);
        ref.read(profilePhotoLocalCacheProvider.notifier).cache(uid, bytes);
        return bytes;
      }
      return null;
    } catch (_) {
      if (attempt < 3) {
        await Future.delayed(Duration(milliseconds: 450 * (attempt + 1)));
      }
    }
  }
  return null;
});

String profilePhotoStoragePath(String uid) => 'profile_photos/$uid.jpg';
