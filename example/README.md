# flutter_twain_scanner Example

A cross-platform document scanning demo built with the `flutter_twain_scanner` package and the [Dynamic Web TWAIN Service REST API](https://www.dynamsoft.com/web-twain/restfulapi/).

| Desktop (macOS) | Mobile (Android) |
|-----------------|------------------|
| ![Example app on macOS](../screenshots/macos_scanner_list.png) | ![Example app on Android](../screenshots/android_scanner_list.png) |

## Getting Started

1. Install the Dynamic Web TWAIN Service on the machine that is connected to the scanners:

   - **Windows**: [Dynamsoft-Service-Setup.msi](https://demo.dynamsoft.com/DWT/DWTResources/dist/DynamsoftServiceSetup.msi)
   - **macOS**: [Dynamsoft-Service-Setup.pkg](https://demo.dynamsoft.com/DWT/DWTResources/dist/DynamsoftServiceSetup.pkg)
   - **Linux**: [Dynamsoft-Service-Setup.deb](https://demo.dynamsoft.com/DWT/DWTResources/dist/DynamsoftServiceSetup.deb), [Dynamsoft-Service-Setup.rpm](https://demo.dynamsoft.com/DWT/DWTResources/dist/DynamsoftServiceSetup.rpm)

2. Request a [free 30-day trial license](https://www.dynamsoft.com/customer/license/trialLicense/?product=dcv&package=cross-platform) and replace `_trialLicense` in `lib/main.dart` with your own key.

3. Run the app on any Flutter platform:

   ```bash
   flutter run -d macos   # or windows, linux, android, ios
   ```

   If the scanners are connected to another machine on the LAN, change the service host (for example `http://192.168.8.72:18625`) in the app.

4. Click the scanner icon to list the scanners, select one and click **Scan Document**. The scanned pages appear in the gallery and are stored as a document by the service. Click **Save PDF** to download the document as a PDF file.

## Regenerating the Screenshots

The README screenshots are rendered with a golden test:

```bash
flutter test test/screenshot_golden_test.dart --update-goldens
```
