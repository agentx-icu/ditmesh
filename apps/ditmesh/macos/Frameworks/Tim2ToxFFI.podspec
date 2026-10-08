# ditmesh: bundle libtim2tox_ffi
#
# Local, binary-only pod that vendors the Tim2Tox FFI dylib staged by
# tool/ci/build_tim2tox.sh --target macos-<arch> (libtim2tox_ffi.dylib next to
# this file; gitignored). CocoaPods treats a vendored dynamic library like a
# framework: it is linked (-ltim2tox_ffi) and copied into
# DitMesh.app/Contents/Frameworks by the "[CP] Embed Pods Frameworks" phase,
# then codesigned with the app. Tim2Tox's Dart loader probes
# `<exe dir>/../Frameworks/libtim2tox_ffi.dylib`, and the patched Tencent SDK's
# NativeLibraryManager falls back to dlopen('libtim2tox_ffi.dylib'), which
# resolves to the already-loaded image of the same leaf name.
# libsodium is linked statically into the dylib by default; with
# --system-libsodium the Homebrew libsodium*.dylib is staged beside it and
# referenced via @loader_path, so the glob below picks it up too.
Pod::Spec.new do |s|
  s.name             = 'Tim2ToxFFI'
  s.version          = '0.1.0'
  s.summary          = 'Tim2Tox FFI shim (c-toxcore + libsodium) for ditmesh, prebuilt.'
  s.description      = 'Prebuilt libtim2tox_ffi.dylib for macOS. Built by tool/ci/build_tim2tox.sh; not published.'
  s.homepage         = 'https://github.com/agentx-icu/tim2tox'
  s.license          = { :type => 'GPL-3.0', :text => 'See third_party/tim2tox/LICENSE' }
  s.author           = { 'ditmesh' => 'noreply@agentx.icu' }
  s.source           = { :path => '.' }
  s.platform         = :osx, '10.15'
  s.osx.deployment_target = '10.15'
  s.vendored_libraries = 'libtim2tox_ffi.dylib', 'libsodium*.dylib'
  s.requires_arc     = false
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'NO' }
end
