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

      imageName = "ansible-omni-deploy"; # an "omni-potent" deploy image, i.e. contains ansible modules for systemd, database, podman etc. management
      imageTags = "ansible2.15.0";

      py = pkgs.python3; # TODO: find out why/by whom some python3.10 deps are pulled in if this is set to 3.11 (=> duplicates)
      # below implies python interpreter itself, do not separately specify!
      pypkgs = [ (py.withPackages (p: with p; [ pexpect ansible-core /* ansible */ jmespath psycopg2 ]))];
      pyenvpaths =
        pypkgs ++
        (with pkgs; [
          (ansible-lint.override { python3=py; })
        ]);
      pyenv = pkgs.buildEnv {
        name = "mypy";
        paths = pyenvpaths;
      };

      # we do pyenv instead of pkgs.ansible, because we need the same python version as for the rest of our env referenced
      ansibleCollectionPath = pkgs.callPackage ./ansible-collections.nix {} pyenv {
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
            # fakeNsss
          ]) ++
          (with pkgs; [
            bash
            git jq mawk toybox
          ]);
      });

    in rec {

      devShell = pkgs.mkShell {
        buildInputs = [ pyenv ] ++ (with pkgs; [ dive nix ]);
        shellHook = ''
          export ANSIBLE_COLLECTIONS_PATHS="${ansibleCollectionPath}"
        '';
      };

      apps = {
        push2reg = {
          type = "app";
          program = let scriptname="push2reg"; in ''${(with pkgs; writeShellScriptBin scriptname ''
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

      packages =
      let
        imgdef = {
          name = imageName;
          tag = imageTags;
          created = "now";
          contents = imgContentDrv;
          config = {
            Cmd = [
              "ansible-playbook" "--version"
            ];
            Env = [
              # "ANSIBLE_PYTHON_INTERPRETER=/bin/python3"
              "ANSIBLE_COLLECTIONS_PATHS=${ansibleCollectionPath}"
            ];
          };
        };
      in {
        ansibleSLImg = pkgs.dockerTools.streamLayeredImage imgdef;
        ansibleBLImg = pkgs.dockerTools.buildLayeredImage imgdef; # !!! LayeredImage doesn't have the bug where copies instead of links are made to the image root
      };
    }
  );
}
