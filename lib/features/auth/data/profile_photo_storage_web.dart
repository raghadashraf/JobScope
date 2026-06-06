import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

const _kPhotoBytesKey = 'user_photo_bytes_b64';

Future<void> savePhotoBytes(String uid, Uint8List bytes) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kPhotoBytesKey, base64Encode(bytes));
}

Future<Uint8List?> loadPhotoBytes(String uid) async {
  final prefs = await SharedPreferences.getInstance();
  final encoded = prefs.getString(_kPhotoBytesKey);
  if (encoded == null || encoded.isEmpty) return null;
  try {
    return base64Decode(encoded);
  } catch (_) {
    return null;
  }
}

Future<void> clearPhotoBytes(String uid) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kPhotoBytesKey);
}
