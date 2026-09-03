import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// Saves [bytes] as [directory]/[fileName] and returns the file path.
///
/// This implementation is compiled on IO platforms (Android, iOS, Windows,
/// macOS and Linux).
Future<String> saveFile(
    String directory, String fileName, Uint8List bytes) async {
  final filePath = p.join(directory, fileName);
  final file = File(filePath);
  await file.writeAsBytes(bytes);
  return filePath;
}
