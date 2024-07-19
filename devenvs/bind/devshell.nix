{pkgs, ...}: let
  inherit (import ./build-inputs.nix {inherit pkgs;}) pyEnv ansibleCollectionPath;
in
  pkgs.mkShell {
    buildInputs = [pyEnv] ++ (with pkgs; [dive nix]);
    shellHook = ''
      export ANSIBLE_COLLECTIONS_PATHS="${ansibleCollectionPath}"
    '';
  }
