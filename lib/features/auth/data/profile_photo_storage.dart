import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

/// Same uid key as [AuthRepository] — one signed-in user per device.
const _kUidKey = 'user_uid';
const _kPhotoBytesKey = 'user_photo_bytes_b64';

/// Persists profile photo bytes in browser localStorage / device prefs.
/// Survives Chrome reload; in-memory caches do not.
class ProfilePhotoStorage {
  static Future<void> save(String uid, Uint8List bytes) async {
    if (bytes.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final savedUid = prefs.getString(_kUidKey);
    if (savedUid != null && savedUid != uid) return;
    if (savedUid == null) await prefs.setString(_kUidKey, uid);
    await prefs.setString(_kPhotoBytesKey, base64Encode(bytes));
  }

  static Future<Uint8List?> load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_kUidKey) != uid) return null;
    final encoded = prefs.getString(_kPhotoBytesKey);
    if (encoded == null || encoded.isEmpty) return null;
    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }
}
