#ifndef RUNNER_RUNTIME_INITIALIZATION_H_
#define RUNNER_RUNTIME_INITIALIZATION_H_

#include <windows.h>
#include <roapi.h>

class RuntimeInitialization {
 public:
  using Initialize = HRESULT(WINAPI*)(RO_INIT_TYPE);
  using Uninitialize = void(WINAPI*)();

  explicit RuntimeInitialization(Initialize initialize = ::RoInitialize,
                                 Uninitialize uninitialize = ::RoUninitialize)
      : result_(initialize(RO_INIT_SINGLETHREADED)),
        uninitialize_(uninitialize) {}

  ~RuntimeInitialization() {
    if (SUCCEEDED(result_)) uninitialize_();
  }

  RuntimeInitialization(const RuntimeInitialization&) = delete;
  RuntimeInitialization& operator=(const RuntimeInitialization&) = delete;
  HRESULT result() const { return result_; }

 private:
  HRESULT result_;
  Uninitialize uninitialize_;
};

#endif  // RUNNER_RUNTIME_INITIALIZATION_H_
