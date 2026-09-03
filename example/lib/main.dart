import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_twain_scanner/flutter_twain_scanner.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const ScannerApp());
}

/// The default endpoint of the Dynamic Web TWAIN Service.
const String _defaultHost = 'http://127.0.0.1:18625';

/// The public trial license of Dynamic Web TWAIN. Request a 30-day trial
/// license at https://www.dynamsoft.com/customer/license/trialLicense/.
const String _trialLicense =
    'DLS2eyJoYW5kc2hha2VDb2RlIjoiMjAwMDAxLTE2NDk4Mjk3OTI2MzUiLCJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSIsInNlc3Npb25QYXNzd29yZCI6IndTcGR6Vm05WDJrcEQ5YUoifQ==';

class ScannerApp extends StatelessWidget {
  const ScannerApp({super.key, this.service});

  final DynamsoftService? service;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter TWAIN Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: ScannerPage(service: service),
    );
  }
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key, this.service});

  /// The service used for all Dynamic Web TWAIN Service requests. Defaults to
  /// a [DynamsoftService]; tests can inject a stub instead.
  final DynamsoftService? service;

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  late final DynamsoftService _service = widget.service ?? DynamsoftService();
  final TextEditingController _hostController =
      TextEditingController(text: _defaultHost);

  List<Map<String, dynamic>> _scanners = [];
  Map<String, dynamic>? _selectedScanner;
  String? _documentId;
  bool _connected = false;
  bool _scanning = false;
  String? _serviceVersion;
  final List<Uint8List> _pages = [];

  @override
  void initState() {
    super.initState();
    _checkService();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _service.close();
    super.dispose();
  }

  String get _host => _hostController.text.trim();

  Future<void> _checkService() async {
    try {
      final info = await _service.getServerInfo(_host);
      if (!mounted) return;
      setState(() {
        _connected = info['compatible'] == true;
        _serviceVersion = info['version']?.toString();
      });
    } on DynamsoftServiceException {
      if (!mounted) return;
      setState(() => _connected = false);
    }
  }

  Future<void> _listScanners() async {
    try {
      final scanners = await _service.getDevices(_host);
      if (!mounted) return;
      setState(() {
        _scanners = scanners;
        _selectedScanner = scanners.isNotEmpty ? scanners.first : null;
      });
      if (scanners.isEmpty) {
        _showMessage('No scanner found on the service.');
      }
    } on DynamsoftServiceException catch (error) {
      _showError('Listing scanners', error);
    }
  }

  Future<void> _scanDocument() async {
    final scanner = _selectedScanner;
    if (scanner == null) {
      _showMessage('Select a scanner first.');
      return;
    }
    setState(() => _scanning = true);
    try {
      _documentId ??= await _service
          .createDocument(_host, {}).then((doc) => doc['uid'] as String);

      final job = await _service.createJob(_host, {
        'license': _trialLicense,
        'device': scanner['device'],
        'config': {
          'IfShowUI': false,
          'PixelType': 2,
          'Resolution': 200,
          'IfFeederEnabled': false,
          'IfDuplexEnabled': false,
        },
      });
      final jobId = job['jobuid'] as String;
      try {
        await _scanPages(jobId);
      } finally {
        await _service.deleteJob(_host, jobId);
      }
    } on DynamsoftServiceException catch (error) {
      _showError('Scanning', error);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  /// Copies every scanned page into the document and shows it in the gallery.
  Future<void> _scanPages(String jobId) async {
    while (true) {
      final infos = await _service.getImageInfo(_host, jobId);
      if (infos.isEmpty) break;

      final source = infos.first['url'] as String?;
      if (source != null && _documentId != null) {
        await _service.insertPage(_host, _documentId!, {
          'password': '',
          'source': source,
        });
      }

      final page = await _service.getNextPage(_host, jobId);
      if (!mounted) return;
      setState(() {
        if (page != null) _pages.insert(0, page);
      });
    }
  }

  Future<void> _savePdf() async {
    if (_documentId == null) {
      _showMessage('Scan a document first.');
      return;
    }
    try {
      final stream = await _service.getDocumentStream(_host, _documentId!);
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/document_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await File(filePath).writeAsBytes(stream);
      if (!mounted) return;
      _showMessage('PDF saved to $filePath');
    } on DynamsoftServiceException catch (error) {
      _showError('Saving the PDF', error);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String action, DynamsoftServiceException error) {
    _showMessage('$action failed: ${error.message} (HTTP ${error.statusCode})');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TWAIN Scanner'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _ConnectionBadge(
              connected: _connected,
              version: _serviceVersion,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            TextField(
              controller: _hostController,
              decoration: InputDecoration(
                labelText: 'Dynamic Web TWAIN Service host',
                hintText: _defaultHost,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _checkService,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Map<String, dynamic>>(
                    initialValue: _selectedScanner,
                    decoration: const InputDecoration(
                      labelText: 'Scanner',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final scanner in _scanners)
                        DropdownMenuItem(
                          value: scanner,
                          child: Text('${scanner['name']}'),
                        ),
                    ],
                    onChanged: (scanner) =>
                        setState(() => _selectedScanner = scanner),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'List scanners',
                  onPressed: _scanning ? null : _listScanners,
                  icon: const Icon(Icons.document_scanner),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _scanning ? null : _scanDocument,
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Scan Document'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _scanning ? null : _savePdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Save PDF'),
                  ),
                ),
              ],
            ),
            if (_scanning) const LinearProgressIndicator(),
            Expanded(
              child: _pages.isEmpty
                  ? _EmptyGallery(scanning: _scanning)
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 480,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _pages.length,
                      itemBuilder: (context, index) => Card(
                        clipBehavior: Clip.antiAlias,
                        child: Image.memory(
                          _pages[index],
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.connected, this.version});

  final bool connected;
  final String? version;

  @override
  Widget build(BuildContext context) {
    final color = connected ? Colors.green : Colors.red;
    return Tooltip(
      message: connected
          ? 'Connected to the Dynamic Web TWAIN Service'
          : 'The Dynamic Web TWAIN Service is not reachable',
      child: Chip(
        avatar: Icon(Icons.circle, size: 12, color: color),
        label: Text(
          connected ? (version ?? 'Online') : 'Offline',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery({required this.scanning});

  final bool scanning;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.document_scanner,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            scanning ? 'Scanning...' : 'Scanned pages appear here',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
