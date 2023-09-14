import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_twain_scanner/flutter_twain_scanner.dart';

import 'dart:ui' as ui;

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
  List<String> _scanners = []; // Option 2
  String? _selectedScanner;
  String host = 'http://127.0.0.1:18622';
  final DynamsoftService dynamsoftService = DynamsoftService();
  List<dynamic> devices = [];
  List<String> imagePaths = [];

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
          't0068MgAAAEm8KzOlKD/AG56RuTf2RSTo4ajLgVpDBfQkmIJYY7yrDj3jbzQpRfQRzGnACr7S1F/7Da6REO20jmF3QR4VDXI=',
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
      final String jobId =
          await dynamsoftService.scanDocument(host, parameters);

      if (jobId != '') {
        print('job id: $jobId');

        List<String> paths =
            await dynamsoftService.getImageFiles(host, jobId, './');

        await dynamsoftService.deleteJob(host, jobId);

        if (paths.isNotEmpty) {
          setState(() {
            imagePaths.insertAll(0, paths);
          });
        }
      }
    } catch (error) {
      print('An error occurred: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  final scanners = await dynamsoftService.getDevices(host);
                  for (var i = 0; i < scanners.length; i++) {
                    devices.add(scanners[i]);
                    _scanners.add(scanners[i]['name']);
                    print('\nIndex: $i, Name: ${scanners[i]['name']}');
                  }
                } catch (error) {
                  print('An error occurred: $error');
                }
                // if (scanners != null) {
                //   setState(() {
                //     // _scanners = scanners;
                //     _selectedScanner = scanners[0];
                //   });
                // }
                if (devices.isNotEmpty) {
                  setState(() {
                    // _scanners = scanners;
                    _selectedScanner = devices[0]['name'];
                  });
                }
              },
              child: const Text('List Scanners')),
          DropdownButton(
            hint: const Text('Select a scanner'), // Not necessary for Option 1
            value: _selectedScanner,
            onChanged: (newValue) {
              setState(() {
                _selectedScanner = newValue;
              });
            },
            items: _scanners.map((location) {
              return DropdownMenuItem(
                value: location,
                child: Text(location),
              );
            }).toList(),
          ),
          MaterialButton(
              textColor: Colors.white,
              color: Colors.blue,
              onPressed: () async {
                if (_selectedScanner != null) {
                  int index = _scanners.indexOf(_selectedScanner!);
                  // imagePaths =
                  //     await _flutterTwainScannerPlugin.scanDocument(index);
                  // setState(() {});
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
            Expanded(
                child: imagePaths.isEmpty
                    ? Image.asset('images/default.png')
                    : ListView.builder(
                        itemCount: imagePaths.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(100.0),
                            child: Image.file(
                              File(imagePaths[index]),
                              fit: BoxFit.contain,
                            ), // Replace with Image.file() for local images
                          );
                        },
                      ))
          ],
        ),
      ),
    );
  }
}
