# flutter_twain_scanner

A Flutter plugin for Windows desktop to scan documents from TWAIN compatible scanners. The C/C++ code is ported from [https://github.com/twain/twain-samples](https://github.com/twain/twain-samples).

![Flutter TWAIN Dynamsoft Service](https://www.dynamsoft.com/codepool/img/2023/09/flutter-twain-dynamsoft-service.gif)

## Usage
- `Future<List<String>?> getDataSources()`: Get the list of TWAIN compatible scanners.
    ```dart
    List<String>? scanners = await _flutterTwainScannerPlugin.getDataSources();
    ```
- `Future<String?> scanDocument(int sourceIndex)`: Scan documents from a selected scanner.
    ```dart
    int index = _scanners.indexOf(_selectedScanner!);
    String? documentPath = await _flutterTwainScannerPlugin.scanDocument(index);
    ```
