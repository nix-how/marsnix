{ writeShellApplication, nixVersions, jq }:
let
  patchedNix = nixVersions.latest.overrideAttrs (_: {
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
  text = ''
    set -euo pipefail
    NIXPKGS_PATH=$(nix eval "$1"#pkgs.path)
    nix-env -f "$NIXPKGS_PATH" -qa --drv-path \
      | tr -s ' ' | cut -d ' ' -f2 \
      | xargs nix show-derivation -r \
      | jq -r 'to_entries | .[] | select(.value.outputs.out.hash).key' \
      | sort -u \
      | xargs nix build --option auto-optimize-store true
  '';

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
