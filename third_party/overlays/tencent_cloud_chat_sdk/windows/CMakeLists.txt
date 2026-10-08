# ditmesh overlay (third_party/overlays/tencent_cloud_chat_sdk): the plugin
# DLL only carries the registrant entry point; ImSDK.dll /
# dart_native_imsdk.dll are not linked or bundled (the Dart side loads
# tim2tox_ffi.dll through dart:ffi).
cmake_minimum_required(VERSION 3.14)
add_compile_options("$<$<C_COMPILER_ID:MSVC>:/source-charset:utf-8>")
add_compile_options("$<$<CXX_COMPILER_ID:MSVC>:/source-charset:utf-8>")
set(PROJECT_NAME "tencent_cloud_chat_sdk")
project(${PROJECT_NAME} LANGUAGES CXX)
cmake_policy(VERSION 3.14...3.25)

set(PLUGIN_NAME "tencent_cloud_chat_sdk_plugin")

add_library(${PLUGIN_NAME} SHARED
  "include/tencent_cloud_chat_sdk/tencent_cloud_chat_sdk_plugin_c_api.h"
  "tencent_cloud_chat_sdk_plugin_c_api.cpp"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE "${PROJECT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# Nothing to bundle next to the app.
set(tencent_cloud_chat_sdk_bundled_libraries
  ""
  PARENT_SCOPE
)
