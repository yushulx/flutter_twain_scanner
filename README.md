# flutter_twain_scanner

![Flutter TWAIN Dynamsoft Service](https://www.dynamsoft.com/codepool/img/2023/09/flutter-twain-dynamsoft-service.gif)

A Flutter plugin that enables you to develop Windows desktop applications for digitizing documents using **TWAIN (32-bit/64-bit)**, **WIA**, **SANE**, **ICA** and **eSCL** scanners. The plugin offers callable methods for both [open-source TWAIN](https://github.com/twain/twain-samples) (**64-bit only**) and the **Dynamsoft Service REST API**.

## Dynamsoft Service REST API
By default, the REST API's host address is set to `http://127.0.0.1:18622`.

| Method | Endpoint        | Description                   | Parameters                         | Response                      |
|--------|-----------------|-------------------------------|------------------------------------|-------------------------------|
| GET    | `/DWTAPI/Scanners`    | Get a list of scanners  | None                               | `200 OK` with scanner list       |
| POST   | `/DWTAPI/ScanJobs`    | Creates a scan job      | `license`, `device`, `config`      | `201 Created` with job ID    |
| GET    | `/DWTAPI/ScanJobs/:id/NextDocument`| Retrieves a document image     | `id`: Job ID   | `200 OK` with image stream    |
| DELETE | `/DWTAPI/ScanJobs/:id`| Deletes a scan job       | `id`: Job ID                      | `200 OK`              |


To make Dynamsoft Service work:
1. Install Dynamsoft Service.
    - Windows: [Dynamsoft-Service-Setup.msi](https://demo.dynamsoft.com/DWT/DWTResources/dist/DynamsoftServiceSetup.msi)
    - macOS: [Dynamsoft-Service-Setup.pkg](https://demo.dynamsoft.com/DWT/DWTResources/dist/DynamsoftServiceSetup.pkg)
    - Linux: 
        - [Dynamsoft-Service-Setup.deb](https://demo.dynamsoft.com/DWT/DWTResources/dist/DynamsoftServiceSetup.deb)
        - [Dynamsoft-Service-Setup-arm64.deb](https://demo.dynamsoft.com/DWT/DWTResources/dist/DynamsoftServiceSetup-arm64.deb)
        - [Dynamsoft-Service-Setup-mips64el.deb](https://demo.dynamsoft.com/DWT/DWTResources/dist/DynamsoftServiceSetup-mips64el.deb)
        - [Dynamsoft-Service-Setup.rpm](https://demo.dynamsoft.com/DWT/DWTResources/dist/DynamsoftServiceSetup.rpm)
        
2. Request a [free trial license](https://www.dynamsoft.com/customer/license/trialLicense?product=dwt).


## Dynamsoft Service Configuration
After installing the Dynamsoft Service, navigate to `http://127.0.0.1:18625/` in a web browser to configure the host and port settings. The default host IP address is set to 127.0.0.1. If you wish to make the service accessible from desktop, mobile, and web applications in your office,  you can update the host setting to a LAN IP address, such as **192.168.8.72**.

![dynamsoft-service-config](https://github.com/yushulx/dynamsoft-service-REST-API/assets/2202306/e2b1292e-dfbd-4821-bf41-70e2847dd51e)


## API Usage

### Open Source TWAIN (Windows 64-bit only)
- `Future<List<String>> getDataSources()`: Get the list of TWAIN compatible scanners.
    ```dart
    List<String> scanners = await _flutterTwainScannerPlugin.getDataSources();
    ```
- `Future<List<String>> scanDocument(int sourceIndex)`: Scan documents from a selected scanner.
    ```dart
    int index = _scanners.indexOf(_selectedScanner!);
    List<String> documentPaths = await _flutterTwainScannerPlugin.scanDocument(index);
    ```

### Dynamsoft Service (Windows, macOS, Linux, Android, iOS and Web)
- `Future<List<dynamic>> getDevices(String host, [int? scannerType])`: Get the list of TWAIN, WIA, and eSCL compatible scanners.
    ```dart
    final DynamsoftService dynamsoftService = DynamsoftService();
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


    The scanner parameter configuration is based on [Dynamsoft Web TWAIN documentation](https://www.dynamsoft.com/web-twain/docs/info/api/Interfaces.html#DeviceConfiguration). 
