## Document Digitization App with Flutter 

https://github.com/yushulx/flutter_twain_scanner/assets/2202306/0e8072c4-c324-48a3-9ade-6543492f849e

## Getting Started
1. Install the [Dynamsoft Service](https://www.dynamsoft.com/codepool/downloads/DynamsoftServiceSetup.msi) on a Windows PC that has one or more document scanners connected to it.
2. Visit `http://127.0.0.1:18625/` in your browser and replace `127.0.0.1` with your LAN IP address. E.g. `http://192.168.8.72:18622`.
    
    ![Dynamsoft Service configuration](https://www.dynamsoft.com/codepool/img/2023/09/dynamsoft-service-ip-configuration.png)

3. Request a [trial license](https://www.dynamsoft.com/customer/license/trialLicense/?product=dcv&package=cross-platform) and update the license in `lib/main.dart`.
    
    ```dart
    final Map<String, dynamic> parameters = {
      'license':
          'LICENSE-KEY',
      'device': devices[index]['device'],
    };
    ```
4. Build and run the app for **Windows**, **Linux**, **macOS**, **Android**, **iOS**, or **Web**. Ensure that the IP address of your device is on the same Local Area Network (LAN) as the PC to which the scanner is connected.
    
    ```dart
    flutter run
    ```
    
    ![Flutter TWAIN scanner Anrdoid](https://www.dynamsoft.com/codepool/img/2023/09/flutter-twain-scanner-android.jpg)