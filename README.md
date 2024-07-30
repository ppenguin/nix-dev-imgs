# NixDevImgs

## Rationale

For developing, running and building software in a deterministic environment, we have come to know
and love (optionally `direnv`-powered) `devShells` (from `flake` outputs), or `shell.nix` (the "former" way.)

To achieve (almost) identical build environments in container images we use in CI/CD pipelines on (e.g. `gitlab`-) runners,
it would be cool if we could automatically reproduce said `devShell` environment in a container image.

> Now we can

## Usage (`flake`)

### The `devShell`

To enter the `devShell`:

```sh
nix develop path/to/flake-dir#<devenv>
```

where `<devenv>` is the name of your environment, corresponding to a directory name under `./devenvs`.

For this to work there must be a corresponding shell definition in `./devenvs/<name>/devshell.nix`

Or automatically load the `devShell` by having a working `direnv` and put in your `.envrc`:

```sh
#!/usr/bin/env bash
# .envrc
...
use flake path/to/flake-dir#<devenvs>
...
```

### Build and Push an Image

To build a compressed container image archive to `/nix/store/...` (using `buildLayeredImage`):

```sh
nix build path/to/flake-dir#<devenv>
podman load <./result   # or docker
```

To build the image and upload it to our internal registry:

```sh
REGISTRY="docker://1nnoserv:15000" REPO="devops-imgs" nix run path/to/flake-dir#push2reg-<devenv>
```

or for a public registry (e.g.):

```sh
REGISTRY="quay.io" REGACCOUNT=reguser DOCKERHUBTOKEN=regpasswd REPO="devops-imgs" nix run path/to/flake-dir#push2reg-<devenv>
# the target will be expanded to:
# quay.io/reguser/devops-imgs/imageName:imageTags
# where imageName and imageTags are set in the flake
```

## Support

You're very welcome to provide PRs with additional environments (i.e. dirs under `./devenvs`), especially for relatively generic cases.

You're also very welcome to help with below TODOs.

## TODO

- [ ] provide a flake template, that allows users to instantiate as a new flake and provide their own `./devenvs/...`. Possibly we could even have the template instantiate selected `<devenv>` dirs, such that we could use it as the "env provider" for specific cases while using appropriate examples from this repo as a starting point?
- [ ] How to build containers for other archs?
