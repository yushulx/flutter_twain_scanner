import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'file_saver.dart';

/// Default endpoint of the Dynamic Web TWAIN Service REST API.
///
/// The service also accepts HTTPS requests on port `18623`
/// (`https://127.0.0.1:18623`).
const String defaultServiceHost = 'http://127.0.0.1:18625';

/// The exception thrown when the Dynamic Web TWAIN Service responds with an
/// error, or when a request cannot be completed.
class DynamsoftServiceException implements Exception {
  /// Creates an exception for an HTTP [statusCode] and a human-readable
  /// [message].
  const DynamsoftServiceException(this.statusCode, this.message);

  /// The HTTP status code returned by the service, or `0` when the request
  /// failed before a response was received (e.g. connection refused).
  final int statusCode;

  /// The error message returned by the service, or the client-side error
  /// message.
  final String message;

  @override
  String toString() => 'DynamsoftServiceException($statusCode): $message';
}

/// Bit flags for the scanner protocols supported by the Dynamic Web TWAIN
/// Service.
///
/// The flags can be combined with the bitwise OR operator to request scanners
/// of several protocols at once, for example:
///
/// ```dart
/// final type = ScannerType.twain | ScannerType.twainX64;
/// final scanners = await service.getDevices(host, type);
/// ```
abstract final class ScannerType {
  /// TWAIN scanners (32-bit, Windows only).
  static const int twain = 0x10;

  /// WIA scanners (Windows only).
  static const int wia = 0x20;

  /// TWAIN scanners (64-bit, Windows only).
  static const int twainX64 = 0x40;

  /// ICA scanners (macOS only).
  static const int ica = 0x80;

  /// SANE scanners (Linux only).
  static const int sane = 0x100;

  /// eSCL/AirScan scanners (Windows, macOS and Linux).
  static const int escl = 0x200;

  /// Wi-Fi Direct scanners.
  static const int wifiDirect = 0x400;

  /// WIA/TWAIN hybrid scanners (Windows only).
  static const int wiaTwain = 0x800;
}

/// The status values of a scan job, as reported by the Dynamic Web TWAIN
/// Service.
abstract final class JobStatus {
  /// The job has been created but not started yet. The scanner is locked
  /// until the job starts, is canceled, or times out.
  static const String pending = 'pending';

  /// The job is being executed by the scanner.
  static const String running = 'running';

  /// The job has been canceled by the client.
  static const String canceled = 'canceled';

  /// The job failed with an error.
  static const String fault = 'fault';
}

/// A pure Dart client for the [Dynamic Web TWAIN Service REST API](https://www.
/// dynamsoft.com/web-twain/restfulapi/).
///
/// The client works on Android, iOS, web, Windows, macOS and Linux because it
/// only depends on `package:http`. Methods that write files to the local disk
/// ([getImageFiles] and [getDocumentFile]) are only available on the native
/// platforms; they throw an [UnsupportedError] on the web.
///
/// All methods throw a [DynamsoftServiceException] when the service returns an
/// error response. The [host] parameter of every method is the base URL of the
/// service, for example `http://127.0.0.1:18625`.
class DynamsoftService {
  /// Creates a client for the Dynamic Web TWAIN Service.
  ///
  /// An optional [client] can be supplied to customize the HTTP transport,
  /// which is useful for testing or for adding middlewares such as proxies.
  DynamsoftService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Closes the underlying HTTP client and releases its resources.
  ///
  /// After calling this method, the client instance should no longer be used.
  void close() {
    _client.close();
  }

  /// Returns the version and compatibility information of the service.
  ///
  /// The returned map contains the `version` of the REST API, whether the
  /// installed modules are `compatible` with it, and the `moduleVersions` of
  /// the individual service modules.
  ///
  /// Throws a [DynamsoftServiceException] if the request fails.
  Future<Map<String, dynamic>> getServerInfo(String host) async {
    final response = await _send('GET', host, '/server/version');
    return _decodeJson(response.body);
  }

  /// Returns the scanners registered with the service.
  ///
  /// Each scanner is described by its `name`, its `type` (one of the
  /// [ScannerType] values) and a `device` JSON string that must be passed to
  /// [createJob] to select the scanner.
  ///
  /// Use [scannerType] to restrict the result to one or more specific
  /// protocols. When it is omitted, all available scanners are returned.
  ///
  /// Throws a [DynamsoftServiceException] if the request fails.
  Future<List<Map<String, dynamic>>> getDevices(
    String host, [
    int? scannerType,
  ]) async {
    var endpoint = '/device/scanners';
    if (scannerType != null) {
      endpoint += '?type=$scannerType';
    }
    final response = await _send('GET', host, endpoint);
    final decoded = json.decode(response.body);
    return [
      for (final device in decoded as List)
        Map<String, dynamic>.from(device as Map),
    ];
  }

  /// Creates a scan job and returns the job description.
  ///
  /// [parameters] accepts the fields of the service's `CreateScanJobOptions`
  /// schema plus a `license` key. The license is sent in the
  /// `DWT-PRODUCT-KEY` request header and removed from the request body:
  ///
  /// - `license`: the product key of Dynamic Web TWAIN.
  /// - `device`: the JSON string of a scanner returned by [getDevices].
  /// - `autoRun`: whether to run the job immediately (defaults to `true`).
  /// - `config`: scan settings such as `IfShowUI`, `PixelType`, `Resolution`,
  ///   `XferCount`, `IfFeederEnabled` and `IfDuplexEnabled`.
  ///
  /// The returned map contains the `jobuid`, the initial `status` (one of the
  /// [JobStatus] values) and the selected `scanner`.
  ///
  /// Throws a [DynamsoftServiceException] if the request fails, for example
  /// when the license is invalid (403).
  Future<Map<String, dynamic>> createJob(
    String host,
    Map<String, dynamic> parameters,
  ) async {
    final body = Map<String, dynamic>.from(parameters)..remove('license');
    final response = await _send(
      'POST',
      host,
      '/device/scanners/jobs',
      body: body,
      headers: {'DWT-PRODUCT-KEY': parameters['license']?.toString() ?? ''},
    );
    return _decodeJson(response.body);
  }

  /// Returns the status of the scan job identified by [jobId].
  ///
  /// The returned map contains the `status` (one of the [JobStatus] values),
  /// an error `code` and a `message`.
  ///
  /// Throws a [DynamsoftServiceException] if the request fails, for example
  /// when the job no longer exists (404 or 410).
  Future<Map<String, dynamic>> checkJob(String host, String jobId) async {
    final response = await _send('GET', host, '/device/scanners/jobs/$jobId');
    return _decodeJson(response.body);
  }

  /// Updates the status of the scan job identified by [jobId].
  ///
  /// A pending job can be started with `{'status': JobStatus.running}` and a
  /// running job can be canceled with `{'status': JobStatus.canceled}`. The
  /// request is ignored by the service when the job is in any other state.
  ///
  /// Throws a [DynamsoftServiceException] if the request fails.
  Future<Map<String, dynamic>> updateJob(
    String host,
    String jobId,
    Map<String, dynamic> parameters,
  ) async {
    final response = await _send(
      'PATCH',
      host,
      '/device/scanners/jobs/$jobId',
      body: parameters,
    );
    return _decodeJson(response.body);
  }

  /// Deletes the scan job identified by [jobId].
  ///
  /// Returns `true` when the service confirms the deletion (204) and `false`
  /// otherwise. Deleting a job also releases the scanner locked by a pending
  /// job.
  Future<bool> deleteJob(String host, String jobId) async {
    final response = await _send(
      'DELETE',
      host,
      '/device/scanners/jobs/$jobId',
    );
    return response.statusCode == 204;
  }

  /// Returns the capabilities of the scanner that runs the scan job
  /// identified by [jobId].
  ///
  /// Throws a [DynamsoftServiceException] if the request fails.
  Future<Map<String, dynamic>> getScannerCapabilities(
    String host,
    String jobId,
  ) async {
    final response = await _send(
      'GET',
      host,
      '/device/scanners/jobs/$jobId/scanner/capabilities',
    );
    return _decodeJson(response.body);
  }

  /// Returns the settings of the scanner that runs the scan job identified by
  /// [jobId].
  ///
  /// The settings are a TWAIN-specific binary blob which can be passed as the
  /// `settings` field of [createJob] to reuse the same scan settings. Only
  /// TWAIN scanners are supported and the scan job must be in the
  /// [JobStatus.pending] state.
  ///
  /// When [showui] is `true`, the scanner's own UI is shown so that the user
  /// can adjust the settings.
  ///
  /// Throws a [DynamsoftServiceException] if the request fails.
  Future<Map<String, dynamic>> getScannerSettings(
    String host,
    String jobId, {
    bool showui = true,
  }) async {
    final response = await _send(
      'GET',
      host,
      '/device/scanners/jobs/$jobId/scanner/settings?showui=$showui',
    );
    return _decodeJson(response.body);
  }

  /// Returns the metadata of the next scanned page of the job identified by
  /// [jobId].
  ///
  /// This request blocks until the next page is ready. Each element of the
  /// returned list describes one page with its `imageuid`, its `imageInfo`
  /// (size, resolution, pixel type) and a `source` URL that can be passed to
  /// [insertPage] to copy the page into a document. The returned list is empty
  /// when the job has no more pages (204).
  ///
  /// Throws a [DynamsoftServiceException] if the request fails.
  Future<List<Map<String, dynamic>>> getImageInfo(
    String host,
    String jobId,
  ) async {
    final response = await _send(
      'GET',
      host,
      '/device/scanners/jobs/$jobId/next-page-info',
    );
    if (response.statusCode == 204) return [];
    final decoded = json.decode(response.body);
    return [
      for (final info in decoded as List)
        Map<String, dynamic>.from(info as Map),
    ];
  }

  /// Fetches the next scanned page of the job identified by [jobId] as a
  /// PNG byte stream.
  ///
  /// Returns `null` when the job has no more pages (204). This request blocks
  /// until the next page is ready.
  ///
  /// Throws a [DynamsoftServiceException] if the request fails.
  Future<Uint8List?> getNextPage(String host, String jobId) async {
    final response = await _send(
      'GET',
      host,
      '/device/scanners/jobs/$jobId/next-page',
    );
    if (response.statusCode == 204) return null;
    return response.bodyBytes;
  }

  /// Fetches all pages of the scan job identified by [jobId] as a list of PNG
  /// byte streams.
  ///
  /// The method polls the service until it reports that the job has no more
  /// pages (204), so it only returns after the scan is complete. Use
  /// [getNextPage] or [getPageStream] instead to display pages while the
  /// scanner is still working.
  ///
  /// Throws a [DynamsoftServiceException] if the request fails.
  Future<List<Uint8List>> getImageStreams(String host, String jobId) async {
    final streams = <Uint8List>[];
    while (true) {
      final stream = await getNextPage(host, jobId);
      if (stream == null) break;
      streams.add(stream);
    }
    return streams;
  }

  /// Fetches all pages of the scan job identified by [jobId] and saves them
  /// as PNG files in [directory].
  ///
  /// Returns the file paths of the saved images, in scanning order. The method
  /// is not supported on the web and throws an [UnsupportedError] there; use
  /// [getImageStreams] instead.
  ///
  /// Throws a [DynamsoftServiceException] if the request fails.
  Future<List<String>> getImageFiles(
    String host,
    String jobId,
    String directory,
  ) async {
    final images = <String>[];
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    var index = 0;
    while (true) {
      final stream = await getNextPage(host, jobId);
      if (stream == null) break;
      final fileName = 'image_${timestamp}_$index.png';
      images.add(await saveFile(directory, fileName, stream));
      index++;
    }
    return images;
  }

  /// Fetches a single page of the scan job identified by [jobId] by its
  /// 0-based [page] index.
  ///
  /// [type] selects the image format, either `image/png` (default) or
  /// `image/jpeg`.
  ///
  /// Throws a [DynamsoftServiceException] if the request fails.
  Future<Uint8List?> getPageStream(
    String host,
    String jobId, {
    int page = 0,
    String type = 'image/png',
  }) async {
    final response = await _send(
      'GET',
      host,
      '/device/scanners/jobs/$jobId/content?type=$type&page=$page',
    );
    return response.bodyBytes;
  }

  /// Creates an empty document in the service's storage and returns its
  /// description.
  ///
  /// [parameters] may contain a `password` (32 characters at most) to
  /// encrypt the document content. The returned map contains the `uid` of the
  /// document and its `pages`.
  ///
  /// Throws a [DynamsoftServiceException] if the request fails.
  Future<Map<String, dynamic>> createDocument(
    String host,
    Map<String, dynamic> parameters,
  ) async {
    final response = await _send(
      'POST',
      host,
      '/storage/documents',
      body: parameters,
    );
    return _decodeJson(response.body);
  }

  /// Returns the metadata of the document identified by [docId].
  ///
  /// The returned map contains the `uid` of the document and the `uid` of
  /// every page. If the document is encrypted, pass its [password].
  ///
  /// Throws a [DynamsoftServiceException] if the request fails.
  Future<Map<String, dynamic>> getDocumentInfo(
    String host,
    String docId, {
    String? password,
  }) async {
    final response = await _send(
      'GET',
      host,
      '/storage/documents/$docId',
      headers: _passwordHeader(password),
    );
    return _decodeJson(response.body);
  }

  /// Replaces the custom metadata of the document identified by [docId].
  ///
  /// [metadata] fully overwrites the existing custom data.
  ///
  /// Throws a [DynamsoftServiceException] if the request fails.
  Future<Map<String, dynamic>> updateDocument(
    String host,
    String docId,
    Object? metadata, {
    String? password,
  }) async {
    final response = await _send(
      'PATCH',
      host,
      '/storage/documents/$docId',
      body: {'metadata': metadata},
      headers: _passwordHeader(password),
    );
    return _decodeJson(response.body);
  }

  /// Deletes the document identified by [docId] from the service's storage.
  ///
  /// Returns `true` when the service confirms the deletion (204) and `false`
  /// otherwise. If the document is encrypted, pass its [password].
  Future<bool> deleteDocument(
    String host,
    String docId, {
    String? password,
  }) async {
    final response = await _send(
      'DELETE',
      host,
      '/storage/documents/$docId',
      headers: _passwordHeader(password),
    );
    return response.statusCode == 204;
  }

  /// Returns the document identified by [docId] as a PDF byte stream.
  ///
  /// If the document is encrypted, pass its [password].
  ///
  /// Throws a [DynamsoftServiceException] if the request fails.
  Future<Uint8List> getDocumentStream(
    String host,
    String docId, {
    String? password,
  }) async {
    final response = await _send(
      'GET',
      host,
      '/storage/documents/$docId/content',
      headers: _passwordHeader(password),
    );
    return response.bodyBytes;
  }

  /// Downloads the document identified by [docId] and saves it as a PDF file
  /// in [directory].
  ///
  /// Returns the file path of the saved document. The method is not supported
  /// on the web and throws an [UnsupportedError] there; use [getDocumentStream]
  /// instead.
  ///
  /// Throws a [DynamsoftServiceException] if the request fails.
  Future<String> getDocumentFile(
    String host,
    String docId,
    String directory, {
    String? password,
  }) async {
    final stream = await getDocumentStream(host, docId, password: password);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return saveFile(directory, 'document_$timestamp.pdf', stream);
  }

  /// Inserts scanned pages into the document identified by [docId] and
  /// returns the updated document description.
  ///
  /// [parameters] accepts:
  ///
  /// - `source` (required): the page URL reported by [getImageInfo].
  /// - `insertPos`: the 1-based position in front of which the page is
  ///   inserted. When omitted, pages are appended to the end of the document.
  /// - `password`: the password of an encrypted document.
  ///
  /// Throws a [DynamsoftServiceException] if the request fails.
  Future<Map<String, dynamic>> insertPage(
    String host,
    String docId,
    Map<String, dynamic> parameters,
  ) async {
    final body = <String, dynamic>{
      'source': parameters['source'],
      if (parameters['insertPos'] != null) 'insertPos': parameters['insertPos'],
    };
    final response = await _send(
      'POST',
      host,
      '/storage/documents/$docId/pages',
      body: body,
      headers: _passwordHeader(parameters['password']?.toString()),
    );
    return _decodeJson(response.body);
  }

  /// Deletes a page from the document identified by [docId].
  ///
  /// [page] can be the `uid` of the page or its 0-based index. Returns `true`
  /// when the service confirms the deletion (204) and `false` otherwise. If
  /// the document is encrypted, pass its [password].
  Future<bool> deletePage(
    String host,
    String docId,
    String page, {
    String? password,
  }) async {
    final response = await _send(
      'DELETE',
      host,
      '/storage/documents/$docId/pages/$page',
      headers: _passwordHeader(password),
    );
    return response.statusCode == 204;
  }

  Map<String, String> _passwordHeader(String? password) =>
      {'DWT-DOC-PASSWORD': password ?? ''};

  Future<http.Response> _send(
    String method,
    String host,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final base = host.endsWith('/') ? host.substring(0, host.length - 1) : host;
    final url = Uri.parse('$base/api$endpoint');
    final requestHeaders = {
      if (body != null) 'Content-Type': 'application/json',
      ...?headers,
    };
    final bodyText = body == null ? null : json.encode(body);
    try {
      late final http.Response response;
      switch (method) {
        case 'GET':
          response = await _client.get(url, headers: requestHeaders);
        case 'POST':
          response = await _client.post(
            url,
            headers: requestHeaders,
            body: bodyText,
            encoding: utf8,
          );
        case 'PATCH':
          response = await _client.patch(
            url,
            headers: requestHeaders,
            body: bodyText,
            encoding: utf8,
          );
        case 'DELETE':
          response = await _client.delete(url, headers: requestHeaders);
        default:
          throw DynamsoftServiceException(0, 'Unsupported method: $method');
      }
      if (response.statusCode >= 400) {
        throw DynamsoftServiceException(
          response.statusCode,
          _errorMessage(response),
        );
      }
      return response;
    } on DynamsoftServiceException {
      rethrow;
    } catch (error) {
      throw DynamsoftServiceException(0, error.toString());
    }
  }

  String _errorMessage(http.Response response) {
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } on FormatException {
      // Fall through to the raw body.
    }
    return response.body.isNotEmpty
        ? response.body
        : response.reasonPhrase ?? '';
  }

  Map<String, dynamic> _decodeJson(String body) {
    final decoded = json.decode(body);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw const DynamsoftServiceException(0, 'Unexpected response format');
  }
}
