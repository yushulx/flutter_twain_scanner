import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_twain_scanner/flutter_twain_scanner.dart';
import 'package:flutter_twain_scanner/dynamsoft_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter TWAIN Scanner',
      home: HomePage(), // Move your logic here
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _flutterTwainScannerPlugin = FlutterTwainScanner();
  List<String> scannerNames = [];
  String? _selectedScanner;
  String host =
      'http://192.168.8.72:18622'; // Visit http://127.0.0.1:18625/ and replace 127.0.0.1 with your LAN IP address to make the service accessible from other devices.
  final DynamsoftService dynamsoftService = DynamsoftService();
  List<Map<String, dynamic>> devices = [];
  List<Uint8List> imagePaths = [];
  String _docId = '';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    if (!mounted) return;
  }

  Future<void> _scanDocument(int index) async {
    if (_docId.isEmpty) {
      Map<String, dynamic> doc =
          await dynamsoftService.createDocument(host, {});

      _docId = doc['uid'];
    }
    final Map<String, dynamic> parameters = {
      'license':
          'DLS2eyJoYW5kc2hha2VDb2RlIjoiMjAwMDAxLTE2NDk4Mjk3OTI2MzUiLCJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSIsInNlc3Npb25QYXNzd29yZCI6IndTcGR6Vm05WDJrcEQ5YUoifQ==',
      'device': devices[index]['device'],
    };

    parameters['config'] = {
      'IfShowUI': false,
      'PixelType': 2,
      // 'XferCount': 1,
      // 'PageSize': 1,
      'Resolution': 200,
      'IfFeederEnabled': false,
      'IfDuplexEnabled': false,
    };

    try {
      final Map<String, dynamic> job =
          await dynamsoftService.createJob(host, parameters);
      final String jobId = job['jobuid'];
      if (jobId != '') {
        // Check job status
        // var info = await dynamsoftService.checkJob(host, jobId);
        // print('Job status: ${info}');

        // // Get capabilities
        // info = await dynamsoftService.getScannerCapabilities(host, jobId);
        // print('Capabilities: ${info}');

        // info = await dynamsoftService
        //     .updateJob(host, jobId, {'status': JobStatus.RUNNING});
        // print('Update job status: ${info}');

        List<Uint8List> paths =
            await dynamsoftService.getImageStreams(host, jobId);

        for (var i = 0; i < paths.length; i++) {
          Map<String, dynamic> imageInfo =
              await dynamsoftService.getImageInfo(host, jobId);

          await dynamsoftService.insertPage(
              host, _docId, {'password': '', 'source': imageInfo['url']});
        }

        if (paths.isNotEmpty) {
          setState(() {
            imagePaths.insertAll(0, paths);
          });
        }

        await dynamsoftService.deleteJob(host, jobId);
      }
    } catch (error) {
      print('An error occurred: $error');
    }
  }

  Future<void> _savePdfFile() async {
    Uint8List? pdfDocumentStream =
        await dynamsoftService.getDocumentStream(host, _docId);

    if (pdfDocumentStream == null) {
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final filePath = path.join(
        dir.path, 'document_${DateTime.now().millisecondsSinceEpoch}.pdf');
    final file = File(filePath);
    await file.writeAsBytes(pdfDocumentStream);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF saved to: $filePath')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter TWAIN Scanner'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    devices.clear();
                    scannerNames.clear();
                    try {
                      final scanners = await dynamsoftService.getDevices(
                        host,
                        ScannerType.TWAINSCANNER | ScannerType.TWAINX64SCANNER,
                      );
                      for (int i = 0; i < scanners.length; i++) {
                        devices.add({
                          'id': '${scanners[i]['device']}_$i',
                          'name': scanners[i]['name'],
                          'device': scanners[i]['device'],
                        });
                        scannerNames.add(scanners[i]['name']);
                      }

                      if (devices.isNotEmpty) {
                        setState(() {
                          _selectedScanner = devices[0]['id'];
                        });
                      }
                    } catch (e) {
                      print('List scanners error: $e');
                    }
                  },
                  child: const Text('List Scanners'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_selectedScanner != null) {
                      final index = devices
                          .indexWhere((d) => d['id'] == _selectedScanner);
                      await _scanDocument(index);
                    }
                  },
                  child: const Text('Scan Document'),
                ),
                ElevatedButton(
                  onPressed: _savePdfFile,
                  child: const Text('Save PDF'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButton(
              isExpanded: true,
              hint: const Text('Select a scanner'),
              value: _selectedScanner,
              onChanged: (newValue) {
                setState(() {
                  _selectedScanner = newValue as String?;
                });
              },
              items: devices.map((device) {
                return DropdownMenuItem(
                  value: device['id'],
                  child: Text(device['name']),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: imagePaths.isEmpty
                  ? Center(child: Image.asset('images/default.png'))
                  : ListView.builder(
                      itemCount: imagePaths.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: SizedBox(
                            height: screenHeight * 0.5,
                            child: Image.memory(
                              imagePaths[index],
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
