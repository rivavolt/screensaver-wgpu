#!/usr/bin/env bash
# Run screensaver on riva (Asahi M2 Mac)
# Uses nix-shell for proper library paths

cd ~/screensaver-gpu
exec nix-shell --run "WAYLAND_DISPLAY=wayland-1 XDG_RUNTIME_DIR=/run/user/1000 ./target/release/screensaver"
