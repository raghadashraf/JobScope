import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import 'profile_photo_storage_platform.dart'
    if (dart.library.io) 'profile_photo_storage_io.dart'
    if (dart.library.html) 'profile_photo_storage_web.dart'
    as platform;

/// Same uid key as [AuthRepository] — one signed-in user per device.
const _kUidKey = 'user_uid';

/// Persists profile photo bytes on disk (mobile/desktop) or localStorage (web).
class ProfilePhotoStorage {
  static Future<void> save(String uid, Uint8List bytes) async {
    if (bytes.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final savedUid = prefs.getString(_kUidKey);
    if (savedUid != null && savedUid != uid) {
      await platform.clearPhotoBytes(savedUid);
    }
    await prefs.setString(_kUidKey, uid);
    await platform.savePhotoBytes(uid, bytes);
  }

  static Future<Uint8List?> load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_kUidKey) != uid) return null;
    return platform.loadPhotoBytes(uid);
  }
}
