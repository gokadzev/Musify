#!/bin/sh
set -eu

bundle_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
binary="$bundle_dir/musify"
icon="$bundle_dir/data/flutter_assets/assets/icons/ic_launcher.png"

if [ ! -x "$binary" ]; then
  printf 'Musify executable not found: %s\n' "$binary" >&2
  exit 1
fi

if [ ! -f "$icon" ]; then
  printf 'Musify icon not found: %s\n' "$icon" >&2
  exit 1
fi

data_home=${XDG_DATA_HOME:-"$HOME/.local/share"}
applications_dir="$data_home/applications"
icons_dir="$data_home/icons/hicolor/96x96/apps"
desktop_file="$applications_dir/com.gokadzev.musify.desktop"
temporary_desktop_file="$desktop_file.tmp.$$"

mkdir -p "$applications_dir" "$icons_dir"
install -m 644 "$icon" "$icons_dir/musify.png"

escaped_binary=$(printf '%s' "$binary" | sed 's/[\\"]/\\&/g; s/%/%%/g')
trap 'rm -f "$temporary_desktop_file"' 0 HUP INT TERM
{
  printf '[Desktop Entry]\n'
  printf 'Name=Musify\n'
  printf 'Comment=Music Streaming app\n'
  printf 'Exec="%s"\n' "$escaped_binary"
  printf 'Icon=musify\n'
  printf 'Terminal=false\n'
  printf 'Type=Application\n'
  printf 'Categories=AudioVideo;Audio;Player;\n'
  printf 'StartupWMClass=com.gokadzev.musify\n'
} > "$temporary_desktop_file"
chmod 644 "$temporary_desktop_file"
mv -f "$temporary_desktop_file" "$desktop_file"

printf 'Installed Musify desktop entry: %s\n' "$desktop_file"
