{pkgs}:
pkgs.mkShell {
  buildInputs = [pyenv] ++ (with pkgs; [dive nix]);
  shellHook = ''
    export ANSIBLE_COLLECTIONS_PATHS="${ansibleCollectionPath}"
  '';
}
