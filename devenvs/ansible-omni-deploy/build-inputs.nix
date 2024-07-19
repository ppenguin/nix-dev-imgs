{pkgs}: let
  pyEnv = pkgs.buildEnv {
    name = "mypy";
    paths = [
      (pkgs.python3.withPackages (p:
        with p; [
          pexpect
          ansible-core
          jmespath
          psycopg2
        ]))
    ];
  };

  # we do pyenv instead of pkgs.ansible, because we need the same python version as for the rest of our env referenced
  ansibleCollectionPath = pkgs.callPackage ./_ansible-collections.nix {} pyEnv {
    "containers-podman" = {
      version = "1.15.3";
      sha256 = "sha256:159qnq3hr94nzasdayhi9xg6rdqi6w8a1h3q4znrp43ybgg61ka7";
    };
    "community-postgresql" = {
      version = "3.4.1";
      sha256 = "sha256:1zwmdbh3zwjijsyi2m05dihfm1brglhq8i4fqg8n0ri9ybdx0lz2";
    };
  };
in {
  inherit pyEnv;
  inherit ansibleCollectionPath;
}
