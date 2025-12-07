{
  description = "Dend collect modules recursive lib extension";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ flake-parts, nixpkgs, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      
      flake = {
        lib = {
          collectModulesRec = dir:
            let
              inherit (builtins)
                readDir
                hasSuffix
                head;
              inherit (nixpkgs.lib)
                splitString
                foldl
                mapAttrsToList;
              entries = readDir dir;
              process = obj: type:
                let
                  isDirectory = type == "directory";
                  isNixFile = type == "regular" && hasSuffix ".nix";
                  getName = file: head (splitString "." file);
                in
                if isDirectory then
                  self.lib.collectModulesRec "${dir}/${obj}"
                else if isNixFile then
                  { "${getName obj}" = import "${dir}/${obj}"; }
                else
                  {};
              processed = mapAttrsToList process entries;
              modules = foldl (acc: moduleSet: acc // moduleSet) {} processed;
            in
            modules;
        };

        overlays.default = final: prev: {
          lib = prev.lib // {
            collectModulesRec = self.lib.collectModulesRec;
          };
        };
      };
    };
}
