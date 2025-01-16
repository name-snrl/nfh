{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nfh.url = "github:name-snrl/nfh";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ nfh, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } rec {
      flake.moduleTree = nfh ./modules;
      imports = flake.moduleTree.flake-parts { }; # import all flake-parts modules
    };
}
