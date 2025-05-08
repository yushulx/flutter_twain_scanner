// ignore_for_file: empty_catches

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

/// Class representing different types of scanners and their corresponding codes.
///
/// This class contains static constants to identify various scanner types like TWAIN, WIA, etc.
/// Each constant holds an integer value that is associated with a specific scanner type.
class ScannerType {
  static const int TWAINSCANNER = 0x10;
  static const int WIASCANNER = 0x20;
  static const int TWAINX64SCANNER = 0x40;
  static const int ICASCANNER = 0x80;
  static const int SANESCANNER = 0x100;
  static const int ESCLSCANNER = 0x200;
  static const int WIFIDIRECTSCANNER = 0x400;
  static const int WIATWAINSCANNER = 0x800;
}

/// Class representing the status of a scan job.
class JobStatus {
  static const String RUNNING = 'running';
  static const String CANCELED = 'canceled';
}

/// A service class for interacting with scanning devices and jobs.
class DynamsoftService {
  /// Fetches the server information from Dynamic Web TWAIN Service.
  ///
  /// [host] - The host server URL.
  ///
  /// Returns a `Map<String, dynamic>` containing the server information.
  Future<Map<String, dynamic>> getServerInfo(String host) async {
    final url = '$host/api/server/version';
    try {
      final response = await http.get(Uri.parse(url));
      return json.decode(response.body);
    } catch (e) {
      return {'version': e.toString(), 'compatible': false};
    }
  }

  /// Fetches the list of available scanners from Dynamic Web TWAIN Service.
  ///
  /// [host] - The host server URL.
  ///
  /// Returns a `List<dynamic>` containing information about available scanners.
  Future<List<dynamic>> getDevices(String host, [int? scannerType]) async {
    String url = '$host/api/device/scanners';
    if (scannerType != null) {
      url += '?type=$scannerType';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (error) {}
    return [];
  }

  /// Creates a new scan job using provided parameters.
  ///
  /// [host] - The host server URL.
  /// [parameters] - The parameters for the scan job.
  ///
  /// Returns a `Map<String, dynamic>` containing the job information.
  Future<Map<String, dynamic>> createJob(
      String host, Map<String, dynamic> parameters) async {
    final url = '$host/api/device/scanners/jobs';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'DWT-PRODUCT-KEY': parameters['license'] ?? '',
          'Content-Length': json.encode(parameters).length.toString()
        },
        body: json.encode(parameters),
      );
      if (response.statusCode == 201) {
        return json.decode(response.body);
      }
    } catch (error) {}
    return {};
  }

  /// Checks the status of a scan job.
  ///
  /// [host] - The host server URL.
  /// [jobId] - The ID of the job to check.
  ///
  /// Returns a `Map<String, dynamic>` containing the job status.
  Future<Map<String, dynamic>> checkJob(String host, String jobId) async {
    final url = '$host/api/device/scanners/jobs/$jobId';
    try {
      final response = await http.get(Uri.parse(url));
      return json.decode(response.body);
    } catch (error) {
      return {};
    }
  }

  /// Updates an existing scan job (e.g., to cancel it).
  ///
  /// [host] - The host server URL.
  /// [jobId] - The ID of the job to update.
  ///
  /// Returns a `Map<String, dynamic>` containing the updated job information.
  Future<Map<String, dynamic>> updateJob(
      String host, String jobId, Map<String, dynamic> parameters) async {
    final url = '$host/api/device/scanners/jobs/$jobId';
    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': json.encode(parameters).length.toString()
        },
        body: json.encode(parameters),
      );
      return json.decode(response.body);
    } catch (error) {
      return {};
    }
  }

  /// Deletes a scan job based on the provided job ID.
  ///
  /// [host] - The host server URL.
  /// [jobId] - The ID of the job to delete.
  ///
  /// Returns a `Map<String, dynamic>` containing the job information.
  Future<Map<String, dynamic>> deleteJob(String host, String jobId) async {
    final url = '$host/api/device/scanners/jobs/$jobId';

    try {
      final response = await http.delete(Uri.parse(url));
      return json.decode(response.body);
    } catch (error) {
      return {};
    }
  }

  /// Saves images from a scan job to a directory.
  ///
  /// [host] - The host server URL.
  /// [jobId] - The ID of the scan job.
  /// [directory] - The directory where images will be saved.
  ///
  /// Returns a `List<String>` containing the paths of saved images.
  Future<List<String>> getImageFiles(
      String host, String jobId, String directory) async {
    final List<String> images = [];
    final url = '$host/api/device/scanners/jobs/$jobId/next-page';
    while (true) {
      try {
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final imagePath = join(directory, 'image_$timestamp.jpg');
          final file = File(imagePath);
          await file.writeAsBytes(response.bodyBytes);
          images.add(imagePath);
        } else if (response.statusCode == 410) {
          break;
        }
      } catch (error) {
        break;
      }
    }

    return images;
  }

  /// Retrieves images as byte streams from a scan job.
  ///
  /// [host] - The host server URL.
  /// [jobId] - The ID of the scan job.
  ///
  /// Returns a `List<Uint8List>` containing the byte streams of the images.
  Future<List<Uint8List>> getImageStreams(String host, String jobId) async {
    final List<Uint8List> streams = [];
    final url = '$host/api/device/scanners/jobs/$jobId/next-page';
    while (true) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          streams.add(response.bodyBytes);
        } else {
          break;
        }
      } catch (error) {
        break;
      }
    }

    return streams;
  }

  /// Get metadata for the next scanned image.
  ///
  /// [host] - The host server URL.
  /// [jobId] - The ID of the scan job.
  ///
  /// Returns a `Map<String, dynamic>` containing the image metadata.
  Future<Map<String, dynamic>> getImageInfo(String host, String jobId) async {
    final url = '$host/api/device/scanners/jobs/$jobId/next-page-info';
    try {
      final response = await http.get(Uri.parse(url));
      return json.decode(response.body);
    } catch (error) {
      return {};
    }
  }

  /// Get scanner capability information.
  ///
  /// [host] - The host server URL.
  /// [jobId] - The ID of the scan job.
  ///
  /// Returns a `Map<String, dynamic>` containing the scanner capabilities.
  Future<Map<String, dynamic>> getScannerCapabilities(
      String host, String jobId) async {
    final url = '$host/api/device/scanners/jobs/$jobId/scanner/capabilities';
    try {
      final response = await http.get(Uri.parse(url));
      return json.decode(response.body);
    } catch (error) {
      return {};
    }
  }

  /// Create a new document from scanned images.
  ///
  /// [host] - The host server URL.
  /// [parameters] - The parameters for the document creation.
  ///
  /// Returns a `Map<String, dynamic>` containing the document information.
  Future<Map<String, dynamic>> createDocument(
      String host, Map<String, dynamic> parameters) async {
    final url = '$host/api/storage/documents';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': json.encode(parameters).length.toString()
        },
        body: json.encode(parameters),
      );
      return json.decode(response.body);
    } catch (error) {
      return {};
    }
  }

  /// Get document metadata.
  ///
  /// [host] - The host server URL.
  /// [docId] - The ID of the document.
  ///
  /// Returns a `Map<String, dynamic>` containing document metadata.
  Future<Map<String, dynamic>> getDocumentInfo(
      String host, String docId) async {
    final url = '$host/api/storage/documents/$docId';
    try {
      final response = await http.get(Uri.parse(url));
      return json.decode(response.body);
    } catch (error) {
      return {};
    }
  }

  /// Delete a document.
  ///
  /// [host] - The host server URL.
  /// [docId] - The ID of the document.
  ///
  /// Returns a `bool` indicating whether the document was deleted successfully.
  Future<bool> deleteDocument(String host, String docId) async {
    final url = '$host/api/storage/documents/$docId';
    try {
      final response = await http.delete(Uri.parse(url));
      return response.statusCode == 204;
    } catch (error) {
      return false;
    }
  }

  /// Download a document (PDF) and save it to the local directory.
  ///
  /// [host] - The host server URL.
  /// [docId] - The ID of the document.
  /// [directory] - The directory where the document will be saved.
  ///
  /// Returns the path of the downloaded document file.
  Future<String> getDocumentFile(
      String host, String docId, String directory) async {
    final url = '$host/api/storage/documents/$docId/content';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final docPath = join(directory, 'document_$timestamp.pdf');
        final file = File(docPath);
        await file.writeAsBytes(response.bodyBytes);
        return docPath;
      }
    } catch (error) {}

    return '';
  }

  /// Get document content as byte stream.
  ///
  /// [host] - The host server URL.
  /// [docId] - The ID of the document.
  ///
  /// Returns a `Uint8List` containing the byte stream of the document content.
  Future<Uint8List?> getDocumentStream(String host, String docId) async {
    final url = '$host/api/storage/documents/$docId/content';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (error) {}

    return null;
  }

  /// Insert a page into a document.
  ///
  /// [host] - The host server URL.
  /// [docId] - The ID of the document.
  /// [parameters] - The parameters for the page insertion.
  ///
  /// Returns a `Map<String, dynamic>` containing the page information.
  Future<Map<String, dynamic>> insertPage(
      String host, String docId, Map<String, dynamic> parameters) async {
    final url = '$host/api/storage/documents/$docId/pages';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'DWT-DOC-PASSWORD': parameters['password'] ?? '',
          'Content-Length': json.encode(parameters).length.toString()
        },
        body: json.encode(parameters),
      );
      return json.decode(response.body);
    } catch (error) {
      return {};
    }
  }

  /// Delete a specific page from a document.
  ///
  /// [host] - The host server URL.
  /// [docId] - The ID of the document.
  /// [pageId] - The ID of the page to delete.
  ///
  /// Returns a `bool` indicating whether the page was deleted successfully.
  Future<bool> deletePage(String host, String docId, String pageId) async {
    final url = '$host/api/storage/documents/$docId/pages/$pageId';
    try {
      final response = await http.delete(Uri.parse(url));
      return response.statusCode == 204;
    } catch (error) {
      return false;
    }
  }
}
