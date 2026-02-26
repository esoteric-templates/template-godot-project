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
      in {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = name;
          version = revision;

          src = ./.;

          nativeBuildInputs = with pkgs; [
            godot

            makeWrapper
          ];

          buildPhase = ''
            mkdir -p $out/share/${name}
            godot \
              --headless \
              --verbose \
              --path . \
              --export-pack "Linux/X11" $out/share/${name}/${name}.pck
          '';

          installPhase = ''
            mkdir -p $out/bin

            makeWrapper ${pkgs.godot}/bin/godot $out/bin/${name} \
              --add-flags "--main-pack" \
              --add-flags "$out/share/${name}/${name}.pck"

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
