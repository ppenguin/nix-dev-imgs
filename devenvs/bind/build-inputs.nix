{pkgs}: {
  commonInputs = with pkgs; [
    buildah
    skopeo
    podman # still needed for container management, can't do all with buildah
    curl
    gnumake
    findutils # for xargs
    qemu # now we (hopefully) have multi-arch capability (requires --privileged, binfmt mounted and configured on runner)
  ];
}
