{
  imgdef = {
    name,
    pkgs,
  }: let
    py = pkgs.python3; # TODO: find out why/by whom some python3.10 deps are pulled in if this is set to 3.11 (=> duplicates)
    # below implies python interpreter itself, do not separately specify!
    pypkgs = [
      (py.withPackages (p:
        with p; [
          pexpect
          ansible-core
          /*
          ansible
          */
          jmespath
          psycopg2
        ]))
    ];
    pyenvpaths =
      pypkgs
      ++ (with pkgs; [
        (ansible-lint.override {python3 = py;})
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
  in {
    inherit name;
    tag = "ansible2.15.0";
    created = "now";
    contents = pkgs.buildEnv {
      name = "image-root";
      paths =
        pyenvpaths
        ++ (with pkgs.dockerTools; [
          usrBinEnv
          binSh
          caCertificates
          # fakeNsss
        ])
        ++ (with pkgs; [
          bash
          git
          jq
          mawk
          toybox
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
  };
}
