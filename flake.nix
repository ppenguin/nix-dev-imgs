{
  description = "Nix devShell devImgs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , flake-utils
    , nixpkgs
    ,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        # pkgs = nixpkgs.legacyPackages.${system};
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfreePredicate = pkg:
              builtins.elem (lib.getName pkg) [
                "nomad"
              ];
          };
          overlays = [
            (final: prev: { })
          ];
        };
        inherit (pkgs) lib;

        genOutAttrs = drv:
          lib.mapAttrs
            (
              name: _:
                if builtins.pathExists ./devenvs/${name}/${drv}.nix
                then
                  import ./devenvs/${name}/${drv}.nix
                    {
                      inherit name pkgs;
                    }
                else { }
            )
            (lib.filterAttrs (_: v: v == "directory") (builtins.readDir ./devenvs));

        genPushApps = lib.mapAttrs'
          (name: value:
            lib.nameValuePair ("push2reg-" + name) {
              type = "app";
              program = import ./lib/push2reg.nix {
                inherit self system pkgs name;
              };
            })
          (lib.filterAttrs (_: v: lib.hasAttr "imageName" v) self.outputs.packages.${system}); # only container image packages
      in
      {
        apps = genPushApps;

        devShells = genOutAttrs "devshell";

        # TODO: how to leverage arch??? (i.e. to build e.g. corresponding arm64 images etc.)
        packages = genOutAttrs "imgdrv";
      }
    );
}
