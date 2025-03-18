{
  nixVersions,
  runCommand,
  nix-eval-jobs,
  jq,
  pkgs,
}:
{
  nixpkgs ? pkgs.path
}:
let
  # nix does not instantiated drv files upon nix-env evaluating them, without this patch
  patchedNix = nixVersions.unstable.overrideAttrs (_: {
    prePatch = ''
      substituteInPlace src/nix-env/nix-env.cc \
        --replace 'settings.readOnlyMode = true' 'settings.readOnlyMode = false'
    '';
  });
  all-drvPaths =
    runCommand "all-drvPaths"
      {
        buildInputs = [
          patchedNix
          nix-eval-jobs
          jq
        ];
        requiredSystemFeatures = [ "recursive-nix" ];
      }
      ''
          set -x
          export NIX_CONFIG="experimental-features = nix-command"

        #  nix-env -f "${nixpkgs}" -qa --drv-path \
        #  nix-eval-jobs --max-memory-size 500 --workers $(expr $(nproc) / 2) --quiet --gc-roots-dir $TMP --eval-store unix:///build/.nix-socket "${nixpkgs}" 2>/dev/null \

          nix-eval-jobs --max-memory-size 1024 --quiet --gc-roots-dir $TMP --eval-store unix:///build/.nix-socket "${nixpkgs}" 2>/dev/null \
            | jq -r 'if .drvPath != null then .drvPath else empty end' \
            | xargs --max-lines=1000 nix derivation show -r \
            | jq -r 'to_entries | .[] | select(.value.outputs.out.hash).key' \
            | sort -u \
            > $out
      '';
  realise-drvPaths =
    runCommand "realise-drvPaths"
      {
        buildInputs = [
          patchedNix
          jq
        ];
        requiredSystemFeatures = [ "recursive-nix" ];
      }
      ''
        set -x
        export NIX_CONFIG="experimental-features = nix-command"

        export DRVS="${all-drvPaths}"
        nix build --impure --option auto-optimize-store true -f ${./read-drvs-from-file.nix}
        cp ${all-drvPaths} $out
      '';
in
realise-drvPaths
