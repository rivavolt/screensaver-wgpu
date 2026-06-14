#!/usr/bin/env bash
# OLED Screensaver launcher
# Press ESC or Q to exit

cd "$(dirname "$0")"
nix-shell --run "./target/release/screensaver"
