{ pkgs }:
let
  subugid = ''
    build:2000:50000
    build:2000:50000
  '';
in
{
  # TODO:
  # Make this nicer, e.g. read a `files/` subdir recursively and include all files found
  # as a text file in the same relative dir in the container

  containersconf = pkgs.writeTextDir "/etc/containers/containers.conf" ''
    [engine]
    # cgroup_manager = "cgroupfs"
    init_path = "${pkgs.catatonit}/bin/catatonit"
  '';

  storageconf = pkgs.writeTextDir "/etc/containers/storage.conf" ''
    [storage]
    driver = "overlay"
    # runroot = "/run/containers/storage"
    # graphroot = "/var/lib/containers/storage"
    runroot = "/var/tmp/bind/containers/storage"
    graphroot = "/var/tmp/bind/lib/containers/storage"

    [storage.options]
    # additionalimagestores = [
    #   "/var/lib/shared",
    #   "/usr/lib/containers/storage",
    # ]

    pull_options = {enable_partial_images = "true", use_hard_links = "false", ostree_repos=""}

    [storage.options.overlay]
    mount_program = "/bin/fuse-overlayfs"
    mountopt = "nodev,fsync=0"
  '';

  registriesconf = pkgs.writeTextDir "/etc/containers/registries.conf" ''
    [registries]
    [registries.block]
    registries = []

    [registries.insecure]
    registries = ["1nnoserv.gtnet.lan:15000"]

    [registries.search]
    registries = ["docker.io", "quay.io", "1nnoserv.gtnet.lan:15000"]
  '';

  policyjson = pkgs.writeTextDir "/etc/containers/policy.json"
    (builtins.toJSON {
      default = [
        {
          "type" = "insecureAcceptAnything";
        }
      ];
      transports = {
        "docker-daemon" =
          {
            "" = [{ "type" = "insecureAcceptAnything"; }];
          };
      };
    });

  subuid = pkgs.writeTextDir "/etc/subuid" subugid;
  subgid = pkgs.writeTextDir "/etc/subgid" subugid;

  # TODO: normally provided by fakeNss, but how to add users?
  passwd = pkgs.writeTextDir "/etc/passwd" ''
    root:x:0:0:root user:/var/empty:/bin/sh
    nobody:x:65534:65534:nobody:/var/empty:/bin/sh
    build:x:1000:100::/var/tmp:/bin/sh
  '';

  group = pkgs.writeTextDir "/etc/group" ''
    root:x:0:
    nobody:x:65534:
    build:x:100:
  '';

  nsswitchconf = pkgs.writeTextDir "/etc/nsswitch.conf" ''
    hosts: files dns
  '';
}
