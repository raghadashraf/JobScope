import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<File> _photoFile(String uid) async {
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}/profile_photo_$uid.jpg');
}

Future<void> savePhotoBytes(String uid, Uint8List bytes) async {
  final file = await _photoFile(uid);
  await file.writeAsBytes(bytes, flush: true);
}

Future<Uint8List?> loadPhotoBytes(String uid) async {
  final file = await _photoFile(uid);
  if (!await file.exists()) return null;
  return file.readAsBytes();
}

Future<void> clearPhotoBytes(String uid) async {
  final file = await _photoFile(uid);
  if (await file.exists()) await file.delete();
}
