# BinD (Buildah-in-Docker)

To build container images with `buildah` in a CI (e.g. `gitlab-runner` with `docker executor`).
Possibly needs some privileges (`docker executor`) settings to work.

The `gitlab-runner` config used with this image has:

```nix
    registrationFlags = [
      "--docker-cap-add SYS_ADMIN --docker-privileged --docker-devices /dev/fuse:rw" # see gitlab-runner register --help
    ];

    ...

    dockerVolumes = [
      "/var/tmp:/var/tmp:rw"
      "/var/tmp:/tmp:rw"
    ];
```
