# ditmesh: bundle libtim2tox_ffi
#
# Local, binary-only pod that vendors the Tim2Tox FFI XCFramework built by
# tool/build_ios_ffi.sh (tim2tox_ffi.xcframework next to this file; gitignored).
# CocoaPods copies the slice matching the build destination into
# Runner.app/Frameworks/tim2tox_ffi.framework and codesigns it, which is the
# path Tim2Tox's Dart loader (`<exe dir>/Frameworks/tim2tox_ffi.framework/tim2tox_ffi`)
# and the patched Tencent SDK's NativeLibraryManager both probe.
# No headers, no sources: the library is only ever dlopen'd from Dart.
Pod::Spec.new do |s|
  s.name             = 'Tim2ToxFFI'
  s.version          = '0.1.0'
  s.summary          = 'Tim2Tox FFI shim (c-toxcore + libsodium) for ditmesh, prebuilt.'
  s.description      = 'Prebuilt libtim2tox_ffi as an XCFramework (iphoneos arm64 + iphonesimulator arm64/x86_64). Built by tool/build_ios_ffi.sh; not published.'
  s.homepage         = 'https://github.com/agentx-icu/tim2tox'
  s.license          = { :type => 'GPL-3.0', :text => 'See third_party/tim2tox/LICENSE' }
  s.author           = { 'ditmesh' => 'noreply@agentx.icu' }
  s.source           = { :path => '.' }
  s.platform         = :ios, '14.0'
  s.ios.deployment_target = '14.0'
  s.vendored_frameworks = 'tim2tox_ffi.xcframework'
  s.requires_arc     = false
  # The framework has no Swift and no module map; nothing to compile.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'NO' }
end
