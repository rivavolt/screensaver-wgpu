{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    wayland
    libxkbcommon
    vulkan-loader
    libGL
    libglvnd
    pkg-config
    rustc
    cargo
  ];

  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
    pkgs.wayland
    pkgs.libxkbcommon
    pkgs.vulkan-loader
    pkgs.libGL
    pkgs.libglvnd
  ];

  WGPU_BACKEND = "gl";
}
