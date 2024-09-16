{
  name,
  pkgs,
}: let
  inherit (import ./build-inputs.nix {inherit pkgs;}) commonInputs;
  inherit
    (import ./_contfiles.nix {inherit pkgs;})
    containersconf
    storageconf
    registriesconf
    policyjson
    passwd
    group
    nsswitchconf
    subuid
    subgid
    ;
  pathsToLink = ["/usr" "/bin" "/var" "/etc"];
  archtag = builtins.getAttr pkgs.system {
    "x86_64-linux" = "amd64";
    "aarch64-linux" = "arm64";
  };
in
  # https://ryantm.github.io/nixpkgs/builders/images/dockertools/
  pkgs.dockerTools.buildLayeredImage {
    inherit name;
    tag = "1.1.1-${archtag}";
    created = "now";
    contents = pkgs.buildEnv {
      name = "image-root";
      inherit pathsToLink;
      paths =
        [
          containersconf
          storageconf
          registriesconf
          policyjson
          subuid
          subgid
          passwd
          group
          nsswitchconf
        ]
        ++ commonInputs
        ++ (with pkgs.dockerTools; [
          # "minimal" container env
          usrBinEnv
          binSh # https://ryantm.github.io/nixpkgs/builders/images/dockertools/#sssec-pkgs-dockerTools-helpers-binSh
          caCertificates
          # fakeNss # this is for /etc/{passwd,group,nsswitch.conf} (what else???)
        ])
        ++ (with pkgs; [
          # "minimal" shell env with some dev tools
          shadow # for newuidmap etc.
          bashInteractive # already have binSh, but this gives us the link /bin/bash
          binutils # for strip
          coreutils
          fuse-overlayfs # for running builder in a container
          git
          gnutar
          gzip
          gawk
          gnused
          jq # needed for our g1tlab package makefiles for API access
          which
        ]);
    };
    config = {
      # NOTE: apparently this throws off gitlab CI runners (at least per default),
      # and leads to them not finding `sh` and failing.
      # Leaving `Cmd` empty appears to work for that case
      # Cmd = [
      #   "buildah"
      #   "--version"
      # ];
      Env = [
        "TEMP=/var/tmp"
      ];
      uid = 1000;
      gid = 100;
    };
  }
