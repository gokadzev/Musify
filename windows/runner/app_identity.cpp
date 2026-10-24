#include "app_identity.h"

#include <windows.h>
#include <shobjidl.h>

#include <filesystem>
#include <iostream>
#include <string>
#include <vector>

namespace {
void SetString(HKEY key, const wchar_t* name, const std::wstring& value) {
  const auto result = RegSetValueExW(
      key, name, 0, REG_SZ, reinterpret_cast<const BYTE*>(value.c_str()),
      static_cast<DWORD>((value.size() + 1) * sizeof(wchar_t)));
  if (result != ERROR_SUCCESS) {
    std::cerr << "Could not update Musify shell identity: " << result << '\n';
  }
}
}  // namespace

void ConfigureAppIdentity() {
  if (FAILED(SetCurrentProcessExplicitAppUserModelID(kMusifyAppId))) {
    std::cerr << "Could not set Musify AppUserModelID\n";
  }

  // Resolve the shell icon relative to the executable for portable bundles.
  std::vector<wchar_t> filename(32768);
  const DWORD length = GetModuleFileNameW(
      nullptr, filename.data(), static_cast<DWORD>(filename.size()));
  if (length == 0 || length >= filename.size()) return;
  const auto icon = std::filesystem::path(std::wstring(filename.data(), length))
                        .parent_path() / L"musify-icon.png";
  if (GetFileAttributesW(icon.c_str()) == INVALID_FILE_ATTRIBUTES) {
    std::cerr << "Musify shell icon is missing from the app bundle\n";
    return;
  }

  const std::wstring subkey =
      std::wstring(L"Software\\Classes\\AppUserModelId\\") + kMusifyAppId;
  HKEY key = nullptr;
  const auto result = RegCreateKeyExW(
      HKEY_CURRENT_USER, subkey.c_str(), 0, nullptr, REG_OPTION_NON_VOLATILE,
      KEY_SET_VALUE, nullptr, &key, nullptr);
  if (result != ERROR_SUCCESS) {
    std::cerr << "Could not register Musify shell identity: " << result << '\n';
    return;
  }
  SetString(key, L"DisplayName", L"Musify");
  SetString(key, L"IconUri", icon.wstring());
  RegCloseKey(key);
}
