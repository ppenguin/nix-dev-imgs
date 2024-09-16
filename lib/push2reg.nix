{
  self,
  system,
  pkgs,
  name,
}: let
  scriptname = "push2reg-${name}";
  imageOut = self.outputs.packages.${system}.${name}.out;
  inherit (self.outputs.packages.${system}.${name}) imageName; # this is the same as ${name}, but more correct (we could also override it in the image derivation)
  imageTags = self.outputs.packages.${system}.${name}.imageTag;
in ''${(
    pkgs.writeShellScriptBin scriptname ''
      if [ -z "$REGISTRY" ] || [ -z "$REPO" ]; then
        echo "Env var REGISTRY and REPO required!"
        exit 1
      fi
      if [ -n "$REGACCOUNT" ] && [ -n "$DOCKERHUBTOKEN" ]; then
        echo "Logging in to the remote REPO=$REPO with user REGACCOUNT=$REGACCOUNT and the password in env var DOCKERHUBTOKEN"
        ${pkgs.podman}/bin/podman login -u "$REGACCOUNT" -p "$DOCKERHUBTOKEN" "$REPO"
      else
        echo "No credentials REGACCOUNT, DOCKERHUBTOKEN given, not logged in"
      fi
      REGACCOUNT=''${REGACCOUNT:+$REGACCOUNT/}
      ${pkgs.podman}/bin/podman load < ${imageOut} && podman push $PUSHFLAGS ${imageName}:${imageTags} "$REGISTRY/$REGACCOUNT$REPO/${imageName}:${imageTags}"
    ''
  )}/bin/${scriptname}''
