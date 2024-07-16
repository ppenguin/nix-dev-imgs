# SuDoF (SuperDevOpsFlake)

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
nix develop path/to/flake-dir
# because this flake only defines one `devShell` attribute, no further specifier is necessary
```

or automatically by having a working `direnv` and put in your `.envrc`:

```sh
#!/usr/bin/env bash
# .envrc
...
use flake path/to/flake-dir
...
```

### Build and Push an Image

To build a compressed container image archive to `/nix/store/...` (using `buildLayeredImage`):

```sh
nix build path/to/flake-dir#ansibleBLImg
podman load </nix/store/compressed-image....tgz   # or docker
```

To build a script that outputs (streams) the uncompressed image to `stdout` when run:

```sh
nix build path/to/flake-dir#ansibleSLImg
./result | podman load   # or docker
```

To build the image and upload it to our internal registry:

```sh
REGISTRY="docker://1nnoserv:15000" REPO="devops-imgs" nix run path/to/flake-dir#push2reg
```

or for a public registry (e.g.):

```sh
REGISTRY="quay.io" REGACCOUNT=reguser DOCKERHUBTOKEN=regpasswd REPO="devops-imgs" nix run path/to/flake-dir#push2reg
# the target will be expanded to:
# quay.io/reguser/devops-imgs/imageName:imageTags
# where imageName and imageTags are set in the flake
```

## Brainstorm / WIP

Maybe better DX/UX if we do the following:

- Define the wanted environments under `devenvs/<envname>` in `nix` files with standardised names and factored such that we have enough flexibility to diverge a bit as necessary between container payload and devshell packages, but still DRY.
- Iterate over `devenvs/` and automatically generate the flake attributes for `devShells` and `packages` (images), where their corresponding names are just that of the subdir.
- The push apps could be generated in the same fashion by iterating over the `packages` outputs (possibly filtering just in case by container packages).

## Limitations

This setup currently is meant to be used as one `flake` per environment, which is in principle the "right way", since it
addresses an environment related to a `git` repo.

The first sensible improvement would be to wrap the derivation functions themselves in a generic way and outfactor them to a
"public library `flake`" that can be used as an input. (This should be trivial.)

Or, instead one could first focus on doing a template, so we don't _include_ it as a library, but instead just copy it as a template?
