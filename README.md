# flutter_twain_scanner

![Flutter TWAIN Dynamsoft Service](https://www.dynamsoft.com/codepool/img/2023/09/flutter-twain-dynamsoft-service.gif)

A Flutter plugin that enables you to develop Windows desktop applications for digitizing documents using TWAIN, WIA, and eSCL scanners. The plugin offers callable methods for both [open-source TWAIN](https://github.com/twain/twain-samples) (**64-bit only**) and the **Dynamsoft Service REST API**, supporting **32-bit and 64-bit TWAIN, WIA, and eSCL** scanners.

## Dynamsoft Service REST API
By default, the REST API's host address is set to `http://127.0.0.1:18622`.

| Method | Endpoint        | Description                   | Parameters                         | Response                      |
|--------|-----------------|-------------------------------|------------------------------------|-------------------------------|
| GET    | `/DWTAPI/Scanners`    | Get a list of scanners  | None                               | `200 OK` with scanner list       |
| POST   | `/DWTAPI/ScanJobs`    | Creates a scan job      | `license`, `device`, `config`      | `201 Created` with job ID    |
| GET    | `/DWTAPI/ScanJobs/:id/NextDocument`| Retrieves a document image     | `id`: Job ID   | `200 OK` with image stream    |
| DELETE | `/DWTAPI/ScanJobs/:id`| Deletes a scan job       | `id`: Job ID                      | `200 OK`              |


To make Dynamsoft Service work:
1. Install [Dynamsoft Service REST Preview for Windows](https://www.dynamsoft.com/codepool/downloads/DynamsoftServiceSetup.msi).
2. Request a [free trial license](https://www.dynamsoft.com/customer/license/trialLicense?product=dwt).


## API Usage

### Open Source TWAIN 
- `Future<List<String>> getDataSources()`: Get the list of TWAIN compatible scanners.
    ```dart
    List<String> scanners = await _flutterTwainScannerPlugin.getDataSources();
    ```
- `Future<List<String>> scanDocument(int sourceIndex)`: Scan documents from a selected scanner.
    ```dart
    int index = _scanners.indexOf(_selectedScanner!);
    List<String> documentPaths = await _flutterTwainScannerPlugin.scanDocument(index);
    ```

### Dynamsoft Service 
- `Future<List<dynamic>> getDevices(String host, [int? scannerType])`: Get the list of TWAIN, WIA, and eSCL compatible scanners.
    ```dart
    String host = 'http://127.0.0.1:18622';
    final scanners = await dynamsoftService.getDevices(host, ScannerType.TWAINSCANNER | ScannerType.TWAINX64SCANNER);
    ```
- `Future<void> deleteJob(String host, String jobId)`: Deletes a scan job based on the provided job ID.
    ```dart
    await dynamsoftService.deleteJob(host, jobId);
    ```
- `Future<List<String>> getImageFiles(String host, String jobId, String directory)`: Saves images from a scan job to a directory.
    ```dart
    List<Uint8List> paths =
            await dynamsoftService.getImageFiles(host, jobId, './');
    ```
- `Future<List<Uint8List>> getImageStreams(String host, String jobId)`: Retrieves image streams from a scan job.
    ```dart
    List<Uint8List> paths =
            await dynamsoftService.getImageStreams(host, jobId);
    ```
- `Future<String> scanDocument(String host, Map<String, dynamic> parameters)`: Creates a new scan job using provided parameters.
    ```dart
    final Map<String, dynamic> parameters = {
      'license':
          'LICENSE-KEY',
      'device': devices[index]['device'],
    };

    parameters['config'] = {
      'IfShowUI': false,
      'PixelType': 2,
      'Resolution': 200,
      'IfFeederEnabled': false,
      'IfDuplexEnabled': false,
    };
    
    final String jobId =
          await dynamsoftService.scanDocument(host, parameters);
    ```


    The parameter configuration is based on [Dynamsoft Web TWAIN documentation](https://www.dynamsoft.com/web-twain/docs/info/api/Interfaces.html#DeviceConfiguration). It controls the behavior of the scanner. 
