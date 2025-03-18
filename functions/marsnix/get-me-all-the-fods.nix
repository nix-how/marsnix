{
  pkgs ? import <nixpkgs> { },
  marsnix ? pkgs.callPackage ./default.nix {},
}:
pkgs.symlinkJoin {
  name = "get-me-all-the-fods";
  paths = map (x: marsnix { nixpkgs = x; }) [
    (builtins.fetchGit {
      url = "https://github.com/NixOS/nixpkgs.git";
      rev = "1272bba1877a9f7cfe1d4d2b62fb36b0e85bd91b";
      allRefs = true;
    })
    (builtins.fetchGit {
      url = "https://github.com/NixOS/nixpkgs.git";
      rev = "f82c0d5417abfb3565275dfedc96bae0c2a8241f";
      allRefs = true;
    })
  ];
}
