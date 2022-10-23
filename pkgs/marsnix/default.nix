{ lib, writeShellApplication, nixVersions, makeWrapper, jq }:
let
  patchedNix = nixVersions.unstable.overrideAttrs (_: {
    prePatch = ''
      substituteInPlace src/nix-env/nix-env.cc \
        --replace 'settings.readOnlyMode = true' 'settings.readOnlyMode = false'
    '';
  });
in
writeShellApplication {
  name = "marsnix";
  runtimeInputs = [
    patchedNix
    jq
  ];
  # TODO: does auto-optimize-store work without configuring it on the daemon
  # TODO: add support for setting --store
  # TODO: instantiating drvs is slow. (take a look at nixpkgs-review)
  text = ''
    set -euo pipefail
    NIXPKGS_PATH=$(nix eval "$1"#pkgs.path)
    echo "instantiating .drv files for all FODs (this might take a few minutes)"
    nix-env -f "$NIXPKGS_PATH" -qa --drv-path \
      | tr -s ' ' | cut -d ' ' -f2 \
      | xargs nix show-derivation -r \
      | jq -r 'to_entries | .[] | select(.value.outputs.out.hash).key' \
      > drvs
    echo "building/downloading FODs"
    DRVS=$(realpath ./drvs)
    export DRVS
    nix build \
      --impure \
      --option auto-optimize-store true \
      -f ${./read-drvs-from-file.nix}
  '';


# TODO: can this be removed?
#  nativeBuildInputs = [ makeWrapper ];

#  installPhase = ''
#    runHook preInstall
#    install -Dm555 marsnix $out/bin/marsnix
#    wrapProgram $out/bin/marsnix \
#      --set PATH "${lib.makeBinPath runtimeInputs}"
#    runHook postInstall
#  '';

  #meta = with lib; {
  #  description = "Taking Nix Offline";
  #  homepage = "https://github.com/nix-how/marsnix";
  #  license = licenses.mit;
  #  platforms = platforms.unix;
  #  maintainers = with maintainers; [ matthewcroughan ];
  #};
}
