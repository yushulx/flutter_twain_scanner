/// File-saving helpers with platform-specific implementations.
///
/// On IO platforms (Android, iOS, Windows, macOS and Linux) files are written
/// to the local disk through `dart:io`. On the web no local file system is
/// available, so the stub implementation is compiled in and throws an
/// [UnsupportedError] at runtime.
library;

export 'file_saver_stub.dart' if (dart.library.io) 'file_saver_io.dart';
