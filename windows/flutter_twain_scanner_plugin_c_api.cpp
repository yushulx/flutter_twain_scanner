#include "include/flutter_twain_scanner/flutter_twain_scanner_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_twain_scanner_plugin.h"

void FlutterTwainScannerPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_twain_scanner::FlutterTwainScannerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
