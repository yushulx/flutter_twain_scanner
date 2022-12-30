#ifndef FLUTTER_PLUGIN_FLUTTER_TWAIN_SCANNER_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_TWAIN_SCANNER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

#include "twain_manager.h"

namespace flutter_twain_scanner {

class FlutterTwainScannerPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterTwainScannerPlugin();

  virtual ~FlutterTwainScannerPlugin();

  // Disallow copy and assign.
  FlutterTwainScannerPlugin(const FlutterTwainScannerPlugin&) = delete;
  FlutterTwainScannerPlugin& operator=(const FlutterTwainScannerPlugin&) = delete;

 private:
    TwainManager *manager; 
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace flutter_twain_scanner

#endif  // FLUTTER_PLUGIN_FLUTTER_TWAIN_SCANNER_PLUGIN_H_
