{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        imports = with inputs; [
          git-hooks-nix.flakeModule
          treefmt-nix.flakeModule
        ];

        systems = lib.systems.flakeExposed;

        perSystem =
          { pkgs, config, ... }:
          {
            devShells.default = config.pre-commit.devShell.overrideAttrs (oa: {
              nativeBuildInputs = oa.nativeBuildInputs or [ ] ++ (with pkgs; [ bashInteractive ]);
            });

            pre-commit.settings.hooks = {
              treefmt = {
                enable = true;
                package = config.treefmt.build.wrapper;
              };
              statix = {
                enable = true; # check. not everything can be fixed, but we need to know what
                settings.format = "stderr";
                settings.config =
                  ((pkgs.formats.toml { }).generate "statix.toml" {
                    disabled = config.treefmt.programs.statix.disabled-lints;
                  }).outPath;
              };
            };

            treefmt = {
              projectRootFile = "flake.nix";
              programs = {
                nixfmt.enable = true;
                deadnix.enable = true;
                statix = {
                  enable = true; # fix, if possible
                  disabled-lints = [ "repeated_keys" ];
                };
                mdformat = {
                  enable = true;
                  package = pkgs.mdformat.withPlugins (
                    p: with p; [
                      mdformat-gfm
                      mdformat-frontmatter
                      mdformat-footnote
                    ]
                  );
                };
              };
              settings.formatter.mdformat.options = [
                "--wrap"
                "80"
              ];
            };
          };
      }
    );
}
