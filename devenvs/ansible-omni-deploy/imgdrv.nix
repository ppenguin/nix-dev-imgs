{
  name,
  pkgs,
}: let
  inherit (import ./build-inputs.nix {inherit pkgs;}) pyEnv ansibleCollectionPath;
in
  pkgs.dockerTools.buildLayeredImage {
    inherit name;
    tag = "ansible2.15.0";
    created = "now";
    contents = pkgs.buildEnv {
      name = "image-root";
      paths =
        [pyEnv]
        ++ (with pkgs.dockerTools; [
          # "minimal" container env
          usrBinEnv
          binSh
          caCertificates
          fakeNss
        ])
        ++ (with pkgs; [
          # "minimal" shell env with some dev tools
          bash
          git
          jq
          mawk
          busybox # toybox too small, e.g. has no tr
          nomad_1_8
        ]);
    };
    config = {
      Cmd = [
        "ansible-playbook"
        "--version"
      ];
      Env = [
        # "ANSIBLE_PYTHON_INTERPRETER=/bin/python3"
        "ANSIBLE_COLLECTIONS_PATHS=${ansibleCollectionPath}"
      ];
    };
  }
