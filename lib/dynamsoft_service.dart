import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

/// A service class for interacting with scanning devices and jobs.
class DynamsoftService {
  
  /// Fetches the list of available scanners from Dynamsoft Service.
  ///
  /// [host] - The host server URL.
  ///
  /// Returns a `List<dynamic>` containing information about available scanners.
  Future<List<dynamic>> getDevices(String host) async {
    List<dynamic> devices = [];
    final url = '$host/DWTAPI/Scanners';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        devices = json.decode(response.body);
        print('\nAvailable scanners: ${devices.length}');
        return devices;
      }
    } catch (error) {
      print(error);
    }
    return [];
  }

  /// Creates a new scan job using provided parameters.
  ///
  /// [host] - The host server URL.
  /// [parameters] - The parameters for the scan job.
  ///
  /// Returns a `String` containing the job ID.
  Future<String> scanDocument(String host, Map<String, dynamic> parameters) async {
    final url = '$host/DWTAPI/ScanJobs';
    try {
      final response = await http.post(
        Uri.parse(url),
        body: json.encode(parameters),
        headers: {'Content-Type': 'application/text'},
      );
      final jobId = response.body;

      if (response.statusCode == 201) {
        return jobId;
      } else {
        print(response.body);
      }
    } catch (error) {
      print(error);
    }
    return '';
  }

  /// Deletes a scan job based on the provided job ID.
  ///
  /// [host] - The host server URL.
  /// [jobId] - The ID of the job to delete.
  Future<void> deleteJob(String host, String jobId) async {
    if (jobId.isEmpty) return;
    final url = '$host/DWTAPI/ScanJobs/$jobId';
    print('Delete job: $url');

    try {
      final response = await http.delete(Uri.parse(url));
      if (response.statusCode == 200) {
        print('Deleted: ${response.body}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  /// Downloads and saves images from a scan job to a directory.
  ///
  /// [host] - The host server URL.
  /// [jobId] - The ID of the scan job.
  /// [directory] - The directory where images will be saved.
  ///
  /// Returns a `List<String>` containing the paths of saved images.
  Future<List<String>> getImageFiles(String host, String jobId, String directory) async {
    final List<String> images = [];
    final url = '$host/DWTAPI/ScanJobs/$jobId/NextDocument';
    print('Start downloading images......');
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
          print('No more images.');
          break;
        }
      } catch (error) {
        print('No more images.');
        break;
      }
    }

    return images;
  }

  /// Downloads images as byte streams from a scan job.
  ///
  /// [host] - The host server URL.
  /// [jobId] - The ID of the scan job.
  ///
  /// Returns a `List<List<int>>` containing the byte streams of the images.
  Future<List<List<int>>> getImageStreams(String host, String jobId) async {
    final List<List<int>> streams = [];
    final url = '$host/DWTAPI/ScanJobs/$jobId/NextDocument';
    print('Start downloading images......');

    while (true) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          streams.add(response.bodyBytes);
        } else if (response.statusCode == 410) {
          print('No more images.');
          break;
        }
      } catch (error) {
        print('No more images.');
        break;
      }
    }

    return streams;
  }
}
