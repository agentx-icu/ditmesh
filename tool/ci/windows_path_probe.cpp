// A disposable CI probe, never linked into DitMesh's shipped executable.
#define NOMINMAX
#include <windows.h>
#include <array>
#include <filesystem>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>
#include "file_io_compat.h"

namespace fs = std::filesystem;

std::string Utf8Path(const fs::path& path) {
  const std::u8string bytes = path.u8string();
  return std::string(bytes.begin(), bytes.end());
}

int wmain(int argc, wchar_t** argv) {
  try {
    if (argc != 2) throw std::runtime_error("Expected one private probe root");
    fs::path root(argv[1]);
    if (!root.is_absolute() || root.native().rfind(L"\\\\?\\", 0) == 0) {
      throw std::runtime_error("Probe requires an absolute path without an extended prefix");
    }
    std::vector<fs::path> directories;
    fs::path directory = root;
    size_t short_directories = 0;
    while (directory.native().size() < 320) {
      const size_t parent_length = directory.native().size();
      const DWORD parent_attributes = GetFileAttributesW(directory.c_str());
      const bool parent_is_directory = parent_attributes != INVALID_FILE_ATTRIBUTES &&
          (parent_attributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
      if (!parent_is_directory) throw std::runtime_error("Probe parent directory is absent");
      directory /= L"数据 path α 01234567890123456789";
      if (!CreateDirectoryW(directory.c_str(), nullptr)) {
        const DWORD error = GetLastError();
        std::cerr << "CreateDirectoryW failure code=" << error
                  << " utf16_length=" << directory.native().size()
                  << " parent_utf16_length=" << parent_length
                  << " parent_directory_verified=true"
                  << " created_short_directories=" << short_directories << '\n';
        return 1;
      }
      if (directory.native().size() <= MAX_PATH) ++short_directories;
      directories.push_back(directory);
    }
    const fs::path file = directory / L"接收 文件 01.bin";
    const fs::path renamed = directory / L"改名 文件 02.bin";
    const std::string name = Utf8Path(file);
    const std::array<unsigned char, 6> content = {0, 1, 127, 128, 254, 255};
    FILE* stream = tim2tox::file_io::OpenUtf8(name, "wb");
    if (!stream) throw std::runtime_error("FFI OpenUtf8 write failed");
    const size_t written = tim2tox::file_io::WriteAt64(stream, 0, content.data(), content.size());
    const int closed = fclose(stream);
    if (written != content.size() || closed != 0) throw std::runtime_error("FFI write/close failed");
    uint64_t size = 0;
    if (!tim2tox::file_io::GetFileSizeUtf8(name, &size) || size != content.size()) {
      throw std::runtime_error("FFI GetFileSizeUtf8 failed");
    }
    stream = tim2tox::file_io::OpenUtf8(name, "rb");
    if (!stream) throw std::runtime_error("FFI OpenUtf8 read failed");
    std::array<unsigned char, 6> actual{};
    const size_t read = tim2tox::file_io::ReadAt64(stream, 0, actual.data(), actual.size());
    const int read_closed = fclose(stream);
    if (read != content.size() || actual != content || read_closed != 0) {
      throw std::runtime_error("FFI read/close failed");
    }
    if (!MoveFileExW(file.c_str(), renamed.c_str(), 0)) throw std::runtime_error("Win32 rename failed");
    if (!tim2tox::file_io::RemoveUtf8(Utf8Path(renamed))) throw std::runtime_error("FFI RemoveUtf8 failed");
    if (GetFileAttributesW(renamed.c_str()) != INVALID_FILE_ATTRIBUTES) {
      throw std::runtime_error("Deleted file still exists");
    }
    for (auto it = directories.rbegin(); it != directories.rend(); ++it) {
      if (!RemoveDirectoryW(it->c_str())) throw std::runtime_error("Win32 directory cleanup failed");
    }
    std::cout << "{\"outcome\":\"passed\",\"utf16_path_length\":" << file.native().size()
              << ",\"bytes_verified\":" << size
              << ",\"scope\":\"same manifest plus pinned FFI file_io_compat; not installed app E2E\"}\n";
    return 0;
  } catch (const std::exception& error) {
    std::cerr << "Native path probe failed: " << error.what() << '\n';
    return 1;
  }
}
