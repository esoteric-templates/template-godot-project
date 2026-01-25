{
  description = "Template for Godot projects";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, self, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        name = "template";
        revision = self.shortRev or self.dirtyShortRev or "unknown";

        runtimeLibs = with pkgs; [
          xorg.libX11
          xorg.libXcursor
          xorg.libXinerama
          xorg.libXrandr
          xorg.libXext
          xorg.libXi

          wayland
          wayland-protocols
          libxkbcommon

          libGL
          vulkan-loader

          alsa-lib
          pipewire
          pulseaudio

          dbus
          udev
        ];
      in {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = name;
          version = revision;

          src = ./.;

          nativeBuildInputs = with pkgs; [
            godot
            godot-export-templates-bin

            xorg.xorgserver
            libGL

            patchelf
            makeWrapper
          ];

          buildPhase = ''
            export HOME=$PWD/home
            export XDG_CACHE_HOME=$HOME/.cache
            export XDG_CONFIG_HOME=$HOME/.config
            export XDG_DATA_HOME=$HOME/.local/share
            export GODOT_USER_PATH=$HOME/.godot

            mkdir -p \
              $XDG_CACHE_HOME \
              $XDG_CONFIG_HOME \
              $XDG_DATA_HOME \
              $GODOT_USER_PATH

            mkdir -p $XDG_DATA_HOME/godot
            ln -s ${pkgs.godot-export-templates-bin}/share/godot/export_templates \
              $XDG_DATA_HOME/godot/export_templates

            mkdir -p build
            godot \
              --headless \
              --verbose \
              --path . \
              --export-release "Linux/X11" build/${name}
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp build/${name} $out/bin/

            patchelf \
              --set-interpreter ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 \
              $out/bin/${name}

            wrapProgram $out/bin/${name} \
              --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath runtimeLibs}

            touch $out/.gdignore
          '';
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            godot
          ];
        };
      }
    );
}
