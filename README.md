# Flutter Document Scanner SDK for TWAIN, WIA, SANE, ICA and eSCL Scanners

![Flutter TWAIN Dynamic Web TWAIN Service](https://www.dynamsoft.com/codepool/img/2023/09/flutter-twain-dynamsoft-service.gif)

A Flutter plugin that enables you to develop cross-platform applications for digitizing documents from **TWAIN (32-bit/64-bit)**, **WIA**, **SANE**, **ICA** and **eSCL** scanners. The plugin offers callable methods for both [open-source TWAIN](https://github.com/twain/twain-samples) (**64-bit only**) and the **Dynamic Web TWAIN Service REST API**.

## ⚙️ Prerequisites

### ✅ Install Dynamic Web TWAIN Service

- **Windows**: [Dynamsoft-Service-Setup.msi](https://demo.dynamsoft.com/DWT/DWTResources/dist/DynamsoftServiceSetup.msi)  
- **macOS**: [Dynamsoft-Service-Setup.pkg](https://demo.dynamsoft.com/DWT/DWTResources/dist/DynamsoftServiceSetup.pkg)  
- **Linux**:  
  - [Dynamsoft-Service-Setup.deb](https://demo.dynamsoft.com/DWT/DWTResources/dist/DynamsoftServiceSetup.deb)  
  - [Dynamsoft-Service-Setup-arm64.deb](https://demo.dynamsoft.com/DWT/DWTResources/dist/DynamsoftServiceSetup-arm64.deb)  
  - [Dynamsoft-Service-Setup-mips64el.deb](https://demo.dynamsoft.com/DWT/DWTResources/dist/DynamsoftServiceSetup-mips64el.deb)  
  - [Dynamsoft-Service-Setup.rpm](https://demo.dynamsoft.com/DWT/DWTResources/dist/DynamsoftServiceSetup.rpm)

### 🔑 Get a License

Request a [free trial license](https://www.dynamsoft.com/customer/license/trialLicense/?product=dcv&package=cross-platform).

## 🧩 Configuration

After installation, open `http://127.0.0.1:18625/` in your browser to configure the **host** and **port** settings.

> By default, the service is bound to `127.0.0.1`. To access it across the LAN, change the host to your local IP (e.g., `192.168.8.72`).

![dynamsoft-service-config](https://github.com/yushulx/dynamsoft-service-REST-API/assets/2202306/e2b1292e-dfbd-4821-bf41-70e2847dd51e)


## 📡 REST API Endpoints

[https://www.dynamsoft.com/web-twain/docs/info/api/restful.html](https://www.dynamsoft.com/web-twain/docs/info/api/restful.html)

## 📚 API Reference for Dynamic Web TWAIN Service

### Scanner Methods

| Method | Description |
|--------|-------------|
| `Future<List<dynamic>> getDevices(String host, [int? scannerType])` | Get a list of scanning devices |
| `Future<Map<String, dynamic>> createJob(String host, Map<String, dynamic> parameters)` | Create a scanning job |
| `Future<Map<String, dynamic>> checkJob(String host, String jobId)` | Check the status of a scan job |
| `Future<Map<String, dynamic>> updateJob(String host, String jobId, Map<String, dynamic> parameters)` | Update a scan job (e.g., cancel it) |
| `Future<void> deleteJob(String host, String jobId)` | Delete a scan job |
| `Future<List<String>> getImageFiles(String host, String jobId, String directory)` | Download and save scanned images |
| `Future<List<Uint8List>> getImageStreams(String host, String jobId)` | Get scanned images as byte streams |
| `Future<Map<String, dynamic>> getImageInfo(String host, String jobId)` | Get info about the next scanned image |
| `Future<Map<String, dynamic>> getScannerCapabilities(String host, String jobId)` | Get supported scanner settings |

The scanner parameter configuration is based on [Dynamsoft Web TWAIN documentation](https://www.dynamsoft.com/web-twain/docs/info/api/Interfaces.html#DeviceConfiguration). 


### Document Methods

| Method | Description |
|--------|-------------|
| `Future<Map<String, dynamic>> createDocument(String host, Map<String, dynamic> parameters)` | Create a document |
| `Future<Map<String, dynamic>> getDocumentInfo(String host, String docId)` | Get document metadata |
| `Future<bool> deleteDocument(String host, String docId)` | Delete a document |
| `Future<String> getDocumentFile(String host, String docId, String directory)` | Download a document PDF to local disk |
| `Future<Uint8List?> getDocumentStream(String host, String docId)` | Get a document as a byte stream |
| `Future<Map<String, dynamic>> insertPage(String host, String docId, Map<String, dynamic> parameters)` | Insert a new page into a document |
| `Future<bool> deletePage(String host, String docId, String pageId)` | Delete a page from a document |


## 🖥️ API Reference for Open Source TWAIN (Windows 64-bit only)

### Scanner Methods

| Method | Description |
|--------|-------------|
| `Future<List<String>> getDataSources()` | Get a list of TWAIN compatible scanners |
| `Future<List<String>> scanDocument(int sourceIndex)` | Scan documents from a selected scanner |





    