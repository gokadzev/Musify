#include "runtime_initialization.h"

#include <cstdlib>
#include <iostream>

namespace {
HRESULT next_result = S_OK;
int initialized = 0;
int uninitialized = 0;

HRESULT WINAPI Initialize(RO_INIT_TYPE type) {
  if (type != RO_INIT_SINGLETHREADED) std::abort();
  ++initialized;
  return next_result;
}

void WINAPI Uninitialize() { ++uninitialized; }

void Require(bool condition) {
  if (!condition) std::abort();
}
}  // namespace

int main() {
  for (const HRESULT result : {S_OK, S_FALSE, E_FAIL, RPC_E_CHANGED_MODE}) {
    next_result = result;
    initialized = uninitialized = 0;
    {
      RuntimeInitialization runtime(Initialize, Uninitialize);
      Require(runtime.result() == result);
      Require(initialized == 1);
      Require(uninitialized == 0);
    }
    Require(uninitialized == (SUCCEEDED(result) ? 1 : 0));
  }
  {
    RuntimeInitialization runtime;
    Require(SUCCEEDED(runtime.result()));
  }
  std::cout << "Windows Runtime success and failure cleanup passed.\n";
}
