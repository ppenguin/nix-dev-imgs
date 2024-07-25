{ pkgs }: {
  commonInputs = with pkgs; [
    buildah
    skopeo
    curl
    gnumake
  ];
}
