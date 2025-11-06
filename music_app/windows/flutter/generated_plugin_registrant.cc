//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <audiotags/audiotags_plugin_c_api.h>
#include <connectivity_plus/connectivity_plus_windows_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  AudiotagsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("AudiotagsPluginCApi"));
  ConnectivityPlusWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ConnectivityPlusWindowsPlugin"));
}
