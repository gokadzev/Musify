"""Verify the actual Windows executable and portable bundle use Musify's icons."""

import ctypes
from ctypes import wintypes
from pathlib import Path
import struct
import sys


def main():
    root = Path(__file__).resolve().parents[2]
    executable = Path(sys.argv[1]).resolve()
    resources = root / "windows/runner/resources"
    canonical = root / "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
    assert (resources / "app_icon.png").read_bytes() == canonical.read_bytes()
    assert (executable.parent / "musify-icon.png").read_bytes() == canonical.read_bytes()

    ico = (resources / "app_icon.ico").read_bytes()
    reserved, kind, count = struct.unpack_from("<HHH", ico)
    assert (reserved, kind) == (0, 1)
    assert count >= 7, "Missing icon sizes for Windows display scaling"

    kernel = ctypes.WinDLL("kernel32", use_last_error=True)
    kernel.LoadLibraryExW.argtypes = [wintypes.LPCWSTR, wintypes.HANDLE, wintypes.DWORD]
    kernel.LoadLibraryExW.restype = wintypes.HMODULE
    kernel.FindResourceW.argtypes = [wintypes.HMODULE, ctypes.c_void_p, ctypes.c_void_p]
    kernel.FindResourceW.restype = wintypes.HRSRC
    kernel.SizeofResource.argtypes = [wintypes.HMODULE, wintypes.HRSRC]
    kernel.SizeofResource.restype = wintypes.DWORD
    kernel.LoadResource.argtypes = [wintypes.HMODULE, wintypes.HRSRC]
    kernel.LoadResource.restype = wintypes.HGLOBAL
    kernel.LockResource.argtypes = [wintypes.HGLOBAL]
    kernel.LockResource.restype = ctypes.c_void_p
    kernel.FreeLibrary.argtypes = [wintypes.HMODULE]
    kernel.FreeLibrary.restype = wintypes.BOOL

    # Load resources without executing application code or starting Flutter.
    module = kernel.LoadLibraryExW(str(executable), None, 0x2 | 0x20)
    if not module:
        raise ctypes.WinError(ctypes.get_last_error())

    def read_resource(identifier, resource_type):
        resource = kernel.FindResourceW(module, identifier, resource_type)
        if not resource:
            raise ctypes.WinError(ctypes.get_last_error())
        size = kernel.SizeofResource(module, resource)
        data = kernel.LockResource(kernel.LoadResource(module, resource))
        if not size or not data:
            raise ctypes.WinError(ctypes.get_last_error())
        return ctypes.string_at(data, size)

    try:
        # IDI_APP_ICON is resource 101 in runner/resource.h.
        group = read_resource(101, 14)  # RT_GROUP_ICON
        assert struct.unpack_from("<HHH", group) == (0, 1, count)
        for index in range(count):
            source = struct.unpack_from("<BBBBHHII", ico, 6 + index * 16)
            embedded = struct.unpack_from("<BBBBHHIH", group, 6 + index * 14)
            # Resource compilers can normalize the ICO plane/bit-depth fields.
            assert embedded[:2] == source[:2], "Embedded icon dimensions differ"
            size, offset = source[6:8]
            actual = read_resource(embedded[7], 3)  # RT_ICON
            assert actual == ico[offset:offset + size], "Executable contains a stale icon"
    finally:
        kernel.FreeLibrary(module)

    print(f"Verified {count} embedded Musify icon sizes and the notification PNG.")


if __name__ == "__main__":
    main()
