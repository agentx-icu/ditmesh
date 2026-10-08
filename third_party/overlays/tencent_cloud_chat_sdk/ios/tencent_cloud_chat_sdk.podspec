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
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
  s.static_framework = true
end
