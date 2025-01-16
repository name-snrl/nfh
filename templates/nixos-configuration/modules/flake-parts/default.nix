{ lib, inputs, ... }:
{
  flake = {
    nixosConfigurations = lib.mapAttrs (
      hostName: cfgModules:
      inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
        };
        modules = [
          # some other imports that will be imported in each configuration.
          # example:
          # inputs.disko.nixosModules.disko
          # inputs.lanzaboote.nixosModules.lanzaboote
          # inputs.agenix.nixosModules.default
          {
            networking = {
              inherit hostName;
            };
          }
        ] ++ cfgModules { };
      }
    ) (lib.removeAttrs inputs.self.moduleTree.nixos.configurations [ "__functor" ]);

    # Example of an overlay that adds an underline colors patch to the foot terminal
    #overlays.default = final: prev: {
    #  foot = prev.foot.overrideAttrs (oa: {
    #    __contentAddressed = true;
    #    patches = [
    #      (final.fetchpatch {
    #        url = "https://codeberg.org/dnkl/foot/pulls/1099.patch";
    #        hash = "sha256-4B+PanJqBC3hANgSYXwXeGO19EBdVMyyIgGawpaIMxE=";
    #      })
    #    ];
    #    mesonFlags = oa.mesonFlags ++ [ "-Dext-underline=enabled" ];
    #  });
    #};
  };
}
