{
  description = "Dend collect modules recursive lib extention";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      flake = {
        overlays.default = final: prev: {
          dend = prev.lib // rec {
            collectModulesRec = dir:
              let
                inherit (builtins)
                  readDir
                  hasSuffix
                  head;

                inherit (prev.lib)
                  splitString
                  foldl;

                enteries = readDir dir;

                process = obj: type:
                  let
                    isDirectory = type == "directory";
                    isNixFile = type == "regular" && hasSuffix ".nix";
                    getName = file: head (splitString "." file);
                  in

                  if isDirectory then
                    collectModulesRec "${dir}/${obj}"
                  else if isNixFile then
                    {"${getName obj}" = import "${dir}/${obj}";}
                  else
                    [];

                processed = prev.lib.mapAttrsToList process enteries;
                modules = foldl (acc: moduleSet: acc // moduleSet) {} processed;
              in
              modules;
          }; 
        };
      };
    };
}

