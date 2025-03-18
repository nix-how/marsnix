{
  description = "Taking Nix Offline";
  nixConfig = {
    extra-substituters = [ "https://matthewcroughan.cachix.org" ];
    extra-trusted-public-keys = [ "matthewcroughan.cachix.org-1:fON2C9BdzJlp1qPan4t5AF0xlnx8sB0ghZf8VDo7+e8=" ];
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs = { self, nixpkgs, flake-parts }:
    flake-parts.lib.mkFlake { inherit self; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      flake = {
        herculesCI.ciSystems = [ "x86_64-linux" ];
        overlay = final: prev: {
          marsnix-cli = self.packages.${prev.stdenv.hostPlatform.system}.marsnix;
          marsnix = self.packages.${prev.stdenv.hostPlatform.system}.marsnix;
        };
      };
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        legacyPackages = {
          marsnix = pkgs.callPackage ./functions/marsnix {};
          marsnix-example-invocation = pkgs.callPackage ./functions/marsnix/get-me-all-the-fods.nix { inherit pkgs; };
        };
        packages = rec {
          default = marsnix-cli;
          marsnix-cli = pkgs.callPackage ./pkgs/marsnix {};
        };
      };
    };
}
