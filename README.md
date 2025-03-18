# Usage

`marsnix` is a function that uses recursive nix to realise all FODs gathered for
a given nixpkgs path. The function expects a path to the root of nixpkgs, where
it will begin evaluating using `nix-eval-jobs`. Below are some valid example invocations:

- ```marsnix { nixpkgs = (builtins.getFlake "github:nixos/nixpkgs/b5883c36db04fb19386d9051e1d77af54225e091"); }```
- ```marsnix { nixpkgs = pkgs.path; }```

You could then map it over a list and symlinkJoin the result in order to fetch all FODs for all the revision(s) you're
interested in. An example of this exists in [./functions/marsnix/get-me-all-the-fods.nix](./functions/marsnix/get-me-all-the-fods.nix), which can also be built as an output of this flake, by running `nix build .#marsnix-example-invocation -L`

```nix
{ marsnix }:
pkgs.symlinkJoin {
  name = "get-me-all-the-fods";
  paths = map (x: marsnix { nixpkgs = x; }) [
    (builtins.fetchGit {
      url = "https://github.com/NixOS/nixpkgs.git";
      rev = "da044451c6a70518db5b730fe277b70f494188f1"; # nixos-24.11
      allRefs = true;
    })
    (builtins.fetchGit {
      url = "https://github.com/NixOS/nixpkgs.git";
      rev = "205fd4226592cc83fd4c0885a3e4c9c400efabb5"; # nixos-23.11
      allRefs = true;
    })
  ];
}
```
