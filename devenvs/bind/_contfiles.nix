{pkgs}: let
  subugid = ''
    build:2000:50000
    build:2000:50000
  '';
in {
  containersconf = pkgs.writeTextDir "/etc/containers/containers.conf" ''
    [engine]
    # cgroup_manager = "cgroupfs"
    init_path = "${pkgs.catatonit}/bin/catatonit"
  '';

  storageconf = pkgs.writeTextDir "/etc/containers/storage.conf" ''
    [storage]
    driver = "overlay"
    mount_program = "${pkgs.fuse-overlayfs}/bin/fuse-overlayfs"
  '';

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
