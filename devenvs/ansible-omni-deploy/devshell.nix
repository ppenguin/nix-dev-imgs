{pkgs, ...}: let
  inherit (import ./build-inputs.nix {inherit pkgs;}) commonInputs;
in
  pkgs.mkShell {
    buildInputs = commonInputs;
    shellHook = ''
    '';
  }
