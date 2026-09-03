import 'dart:typed_data';

/// Saves [bytes] as [directory]/[fileName] and returns the file path.
///
/// This stub is compiled on platforms without a local file system (the web).
/// It throws an [UnsupportedError]; byte-stream methods such as
/// `getImageStreams` should be used instead.
Future<String> saveFile(
    String directory, String fileName, Uint8List bytes) async {
  throw UnsupportedError(
    'Saving files to disk is not supported on this platform. '
    'Use the byte-stream methods instead.',
  );
}
