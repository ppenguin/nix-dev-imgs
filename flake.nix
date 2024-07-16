{
  description = "Nix devShell devImgs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    flake-utils,
    nixpkgs,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        apps = {
          push2reg = {
            type = "app";
            program = let scriptname = "push2reg"; in ''${(with pkgs;
                writeShellScriptBin scriptname ''
                  if [ -z "$REGISTRY" ] || [ -z "$REPO" ]; then
                    echo "Env var REGISTRY and REPO required!"
                    exit 1
                  fi
                  if [ -n "$REGACCOUNT" ] && [ -n "$DOCKERHUBTOKEN" ]; then
                    echo "Logging in to the remote REPO=$REPO with user REGACCOUNT=$REGACCOUNT and the password in env var DOCKERHUBTOKEN"
                    podman login -u "$REGACCOUNT" -p "$DOCKERHUBTOKEN" "$REPO"
                  else
                    echo "No credentials REGACCOUNT, DOCKERHUBTOKEN given, not logged in"
                  fi
                  REGACCOUNT=''${REGACCOUNT:+$REGACCOUNT/}
                  podman load < ${self.outputs.packages.${system}.ansibleBLImg.out} && podman push ${imageName}:${imageTags} "$REGISTRY/$REGACCOUNT$REPO/${imageName}:${imageTags}"
                '')}/bin/${scriptname}'';
          };
        };

        devShells = {
          ansible-omni-deploy = import ./devenvs/ansible/devshell.nix {inherit pkgs;};
        };

        packages = {
          ansibleBLImg = pkgs.dockerTools.buildLayeredImage (import ./ansible/imgdef.nix {
            name = "ansible-omni-deploy";
            inherit pkgs;
          }); # !!! LayeredImage doesn't have the bug where copies instead of links are made to the image root
        };
      }
    );
}
