## 3.0.0

* Rewrote the package in pure Dart, so it now supports Android, iOS, web, Windows, macOS and Linux.
* Removed the native method channel implementations and the open-source TWAIN support. All scanning is done through the Dynamic Web TWAIN Service REST API.
* Added `getScannerSettings`, `getNextPage`, `getPageStream` and `updateDocument` methods.
* Replaced the silent error handling with `DynamsoftServiceException`.
* Renamed `ScannerType` and `JobStatus` constants to lowerCamelCase.
* Normalized the `next-page-info` response, which may be a JSON object or array depending on the service version.
* Added unit tests and a Material 3 example app.

## 2.0.1
* Renamed custom headers for Dynamic Web TWAIN v19.1.

## 2.0.0
* Added support for Dynamic Web TWAIN v19.

## 1.0.2
* Fixed Android build issue.
* Check 404 error when fetching the document stream.

## 1.0.1
* Support AGP 8 for Android.

## 1.0.0
* Updated Dynamsoft Service installer for Windows, macOS and Linux.

## 0.2.1
* Added scanner type filter.

## 0.2.0
* Added support for utilizing the Dynamsoft Service REST API, which allows seamless scanning functionality with both 32-bit and 64-bit TWAIN drivers on Windows desktops. Additionally, the API also offers compatibility with WIA-enabled scanners.

## 0.1.0

* Flutter plugin for scanning documents from TWAIN compatible scanners on Windows desktop.
