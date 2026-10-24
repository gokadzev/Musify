#ifndef RUNNER_APP_IDENTITY_H_
#define RUNNER_APP_IDENTITY_H_

// Identify Musify consistently in the Windows shell.
inline constexpr wchar_t kMusifyAppId[] = L"com.gokadzev.musify";

// Register the shell identity before creating any windows.
void ConfigureAppIdentity();

#endif  // RUNNER_APP_IDENTITY_H_
