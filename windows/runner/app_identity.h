#ifndef RUNNER_APP_IDENTITY_H_
#define RUNNER_APP_IDENTITY_H_

// Keep this ID in sync with the installer's AppUserModelID on shortcuts.
inline constexpr wchar_t kMusifyAppId[] = L"com.gokadzev.musify";

// Register the current executable's shell identity before creating any windows.
// Also runs for the portable distribution, which has no installer registration.
void ConfigureAppIdentity();

#endif  // RUNNER_APP_IDENTITY_H_
