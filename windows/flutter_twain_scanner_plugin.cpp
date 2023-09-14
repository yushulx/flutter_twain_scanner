#include "flutter_twain_scanner_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

namespace flutter_twain_scanner
{

  // static
  void FlutterTwainScannerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarWindows *registrar)
  {
    auto channel =
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "flutter_twain_scanner",
            &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<FlutterTwainScannerPlugin>();

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto &call, auto result)
        {
          plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    registrar->AddPlugin(std::move(plugin));
  }

  FlutterTwainScannerPlugin::FlutterTwainScannerPlugin()
  {
    manager = new TwainManager();
  }

  FlutterTwainScannerPlugin::~FlutterTwainScannerPlugin()
  {
    delete manager;
  }

  void FlutterTwainScannerPlugin::HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
  {
    const auto *arguments = std::get_if<EncodableMap>(method_call.arguments());

    if (method_call.method_name().compare("getPlatformVersion") == 0)
    {
      std::ostringstream version_stream;
      version_stream << "Windows ";
      if (IsWindows10OrGreater())
      {
        version_stream << "10+";
      }
      else if (IsWindows8OrGreater())
      {
        version_stream << "8";
      }
      else if (IsWindows7OrGreater())
      {
        version_stream << "7";
      }
      result->Success(flutter::EncodableValue(version_stream.str()));
    }
    else if (method_call.method_name().compare("getDataSources") == 0)
    {
      result->Success(manager->getDataSources());
    }
    else if (method_call.method_name().compare("scanDocument") == 0)
    {
      int index = -1;
      EncodableList value;

      if (arguments)
      {
        auto index_it = arguments->find(EncodableValue("index"));
        if (index_it != arguments->end())
        {
          index = std::get<int>(index_it->second);
        }
        value = manager->scanDocument(index);
      }
      result->Success(value);
    }
    else
    {
      result->NotImplemented();
    }
  }

} // namespace flutter_twain_scanner
