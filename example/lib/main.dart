import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_twain_scanner/flutter_twain_scanner.dart';
import 'package:flutter_twain_scanner/dynamsoft_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _flutterTwainScannerPlugin = FlutterTwainScanner();
  List<String> scannerNames = [];
  String? _selectedScanner;
  String host =
      'http://192.168.8.72:18622'; // Visit http://127.0.0.1:18625/ and replace 127.0.0.1 with your LAN IP address to make the service accessible from other devices.
  final DynamsoftService dynamsoftService = DynamsoftService();
  List<Map<String, dynamic>> devices = [];
  List<Uint8List> imagePaths = [];

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
        List<Uint8List> paths =
            await dynamsoftService.getImageStreams(host, jobId);

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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    Row row = Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          MaterialButton(
              textColor: Colors.white,
              color: Colors.blue,
              onPressed: () async {
                // List<String>? scanners =
                //     await _flutterTwainScannerPlugin.getDataSources();

                try {
                  devices.clear();
                  scannerNames.clear();
                  final scanners = await dynamsoftService.getDevices(host,
                      ScannerType.TWAINSCANNER | ScannerType.TWAINX64SCANNER);
                  for (var i = 0; i < scanners.length; i++) {
                    devices.add({
                      'id': '${scanners[i]['device']}_$i',
                      'name': scanners[i]['name'],
                      'device': scanners[i]['device'],
                    });
                    scannerNames.add(scanners[i]['name']);
                  }
                } catch (error) {
                  print('An error occurred: $error');
                }
                // if (scanners != null) {
                //   setState(() {
                //     // scannerNames = scanners;
                //     _selectedScanner = scanners[0];
                //   });
                // }
                if (devices.isNotEmpty) {
                  setState(() {
                    _selectedScanner = devices[0]['id'];
                  });
                }
              },
              child: const Text('List Scanners')),
          MaterialButton(
              textColor: Colors.white,
              color: Colors.blue,
              onPressed: () async {
                if (_selectedScanner != null) {
                  int index = devices
                      .indexWhere((device) => device['id'] == _selectedScanner);
                  await _scanDocument(index);
                }
              },
              child: const Text('Scan Document')),
        ]);

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter TWAIN Scanner'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: 100,
              child: row,
            ),
            DropdownButton(
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
            Expanded(
                child: imagePaths.isEmpty
                    ? Image.asset('images/default.png')
                    : ListView.builder(
                        itemCount: imagePaths.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: SizedBox(
                              height: screenHeight * 0.5,
                              child: Image.memory(
                                imagePaths[index],
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        },
                      ))
          ],
        ),
      ),
    );
  }
}
