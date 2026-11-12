# App-local release CRT for the selected MSVC target (never the runner CPU).
# CMake derives CMAKE_MSVC_ARCH from MSVC_CXX_ARCHITECTURE_ID and locates the
# matching toolchain redistributables. Do not copy DLLs from Windows/System32.
if(NOT MSVC)
  message(FATAL_ERROR "Windows runtime packaging requires the MSVC toolchain")
endif()
set(CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP TRUE)
set(CMAKE_INSTALL_DEBUG_LIBRARIES FALSE)
set(CMAKE_INSTALL_DEBUG_LIBRARIES_ONLY FALSE)
set(CMAKE_INSTALL_UCRT_LIBRARIES FALSE)
set(CMAKE_INSTALL_MFC_LIBRARIES FALSE)
set(CMAKE_INSTALL_OPENMP_LIBRARIES FALSE)
include(InstallRequiredSystemLibraries)

set(_runtime_names "")
foreach(_runtime IN LISTS CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS)
  if(NOT EXISTS "${_runtime}")
    message(FATAL_ERROR "Missing MSVC redistributable: ${_runtime}")
  endif()
  get_filename_component(_name "${_runtime}" NAME)
  string(TOLOWER "${_name}" _name)
  if(_name MATCHES "d\\.dll$")
    message(FATAL_ERROR "Debug MSVC runtimes are not redistributable: ${_name}")
  endif()
  list(APPEND _runtime_names "${_name}")
endforeach()
foreach(_required msvcp140.dll vcruntime140.dll vcruntime140_1.dll)
  if(NOT _required IN_LIST _runtime_names)
    message(FATAL_ERROR "Required app-local MSVC runtime missing: ${_required}")
  endif()
endforeach()
install(FILES ${CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS}
  DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  CONFIGURATIONS Profile Release COMPONENT Runtime)

string(REPLACE ";" "\n" _runtime_names "${_runtime_names}")
set(_notice "${CMAKE_CURRENT_BINARY_DIR}/MSVC-runtime.txt")
file(WRITE "${_notice}" "Microsoft Visual C++ Runtime\nCopyright Microsoft Corporation.\n\nUnmodified redistributable libraries from the installed Visual Studio toolchain.\nThese Microsoft components use separate Microsoft Software License Terms;\nthe application's GPL license does not relicense them.\n\nMSVC toolset: ${MSVC_TOOLSET_VERSION}\nCompiler: ${CMAKE_CXX_COMPILER_VERSION}\nTarget: ${CMAKE_MSVC_ARCH}\nFiles:\n${_runtime_names}\n\nLicense directory: https://visualstudio.microsoft.com/license-terms/\nRedistribution conditions: https://learn.microsoft.com/en-us/cpp/windows/redistributing-visual-cpp-files\nVS 2022 distributable list: https://learn.microsoft.com/en-us/visualstudio/releases/2022/redistribution\n\nThe release owner must retain the license applicable to the actual toolchain,\nconfirm redistribution rights, and service app-local runtimes with app updates.\nNo system-wide runtime installation or automatic runtime updater is performed.\n")
install(FILES "${_notice}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}/licenses"
  CONFIGURATIONS Profile Release COMPONENT Runtime)
