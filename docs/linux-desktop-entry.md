# Linux desktop integration

The Linux bundle includes `share/applications/musify.desktop` and the Musify icon. The MPRIS identity uses that desktop entry to identify the app in system media controls.

For a manually extracted bundle, make `musify` available on your PATH and run these commands from the bundle directory:

```sh
install -Dm644 share/applications/musify.desktop "$HOME/.local/share/applications/musify.desktop"
install -Dm644 share/icons/hicolor/192x192/apps/musify.png "$HOME/.local/share/icons/hicolor/192x192/apps/musify.png"
```

The bundle does not install files into the system automatically.
