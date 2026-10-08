#
# ditmesh overlay (third_party/overlays/tencent_cloud_chat_sdk): the plugin's
# Dart side drives libtim2tox_ffi; no Tencent framework is linked.
#
Pod::Spec.new do |s|
  s.name             = 'tencent_cloud_chat_sdk'
  s.version          = '8.0.0'
  s.summary          = 'Tencent Cloud Chat SDK For Flutter (ditmesh headless overlay)'
  s.description      = 'Dart bindings only; the native IM SDK is not linked (ditmesh talks to libtim2tox_ffi).'
  s.homepage         = 'https://trtc.io/products/chat'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Tencent' => 'xingchenhe@tencent.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.11'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
