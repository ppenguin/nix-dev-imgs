{
  description = "ansible shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, flake-utils, nixpkgs }:

  flake-utils.lib.eachDefaultSystem (system:

    let
      pkgs = nixpkgs.legacyPackages.${system};

      inherit (pkgs) lib;

      py = pkgs.python310;
      # below implies python interpreter itself, do not separately specify!
      pypkgs = [ (py.withPackages (p: with p; [ pexpect ansible-core jmespath psycopg2 ]))];
      pyenvpaths = pypkgs ++ (with pkgs; [ ansible-lint ]);
      pyenv = pkgs.buildEnv {
        name = "mypy";
        paths = pyenvpaths;
      };

      ansibleCollectionPath = pkgs.callPackage ./ansible-collections.nix {} pkgs.ansible {
        "containers-podman" = {
            version = "1.10.2";
            sha256 = "sha256:1g74pi0fslgbcp80710q42pfaifiai9hwaz69mi1bm8lqiz79ip8";
        };
        "community-postgresql" = {
          version = "3.0.0";
            sha256 = "sha256:0smahm498jqml389rvx4wmjmn9pkw46dkb6mgarw9bcks3g41i8i";
        };
      };

      imgContentDrv = (pkgs.buildEnv {
        name = "image-root";
        paths =
          pyenvpaths ++
          (with pkgs.dockerTools; [
            usrBinEnv
            binSh
            caCertificates
            fakeNss
          ]) ++
          (with pkgs; [
            git jq gawk toybox
          ]);
      });

    in {

      devShell = pkgs.mkShell {
        buildInputs = [ pyenv ] ++ (with pkgs; [ dive ]);
        ## Apparently we have to set the path explicitly to make it override other (global) python interpreters
        shellHook = ''
          export ANSIBLE_COLLECTIONS_PATHS="${ansibleCollectionPath}"
        '';
      };

      packages = {

        ansibleSLImg = pkgs.dockerTools.streamLayeredImage {
          name = "ansible-omni-deploy"; # an "omni-potent" deploy image, i.e. contains ansible modules for systemd, database, podman etc. management
          tag = "latest";

          contents = imgContentDrv;

          config = {
            Cmd = [
              "ansible-playbook" "--version"
            ];
          };
        };

        ansibleBLImg = pkgs.dockerTools.buildLayeredImage {
          name = "ansible-omni-deploy"; # an "omni-potent" deploy image, i.e. contains ansible modules for systemd, database, podman etc. management
          tag = "latest";

          contents = imgContentDrv;

          config = {
            Cmd = [
              "ansible-playbook" "--version"
            ];
          };
        };

        ansibleImg = pkgs.dockerTools.buildImage {
          name = "ansible-omni-deploy"; # an "omni-potent" deploy image, i.e. contains ansible modules for systemd, database, podman etc. management
          tag = "latest";

          copyToRoot = imgContentDrv;
          extraCommands = ''
          '';

          config = {
            Cmd = [
              "ansible-playbook" "--version"
            ];
          };
        };

      };

    }
  );
}
