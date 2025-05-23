{
  description = "The NFH helps you create lists of files from your Nix File Hierarchy.";

  inputs.nixpkgs.url = "github:nix-community/nixpkgs.lib";

  outputs =
    { nixpkgs, ... }:
    {
      templates.default = {
        description = "NixOS configuration template.";
        path = templates/nixos-configuration;
      };

      __functor =
        with nixpkgs.lib;
        self: dir:
        pipe dir [
          builtins.readDir
          (filterAttrs (name: type: type == "directory" || hasSuffix ".nix" name))
          (mapAttrs' (
            name: type:
            if type == "directory" then
              nameValuePair name (self (dir + "/${name}"))
            else if name == "default.nix" then
              nameValuePair "self" (dir + "/${name}")
            else
              nameValuePair (removeSuffix ".nix" name) (dir + "/${name}")
          ))
        ]
        # add functor to generate a list of files at any level of `fileSet`
        // {
          __functor =
            self: filterSet:
            let
              fileSet = filterAttrsRecursive (name: _: name != "__functor") self;
              filterSet' = filterAttrsRecursive (name: _: !elem name specials) filterSet;

              specials = [
                "_defaultsRecursive"
                "_defaults"
              ];

              validate = {
                path = [ ];
                __functor =
                  self:
                  mapAttrs (
                    name: value:
                    let
                      currentPath = self.path ++ singleton name;
                    in
                    throwIfNot (elem name specials || hasAttrByPath currentPath fileSet)
                      ''
                        '${concatStringsSep "." currentPath}' doesn't exist in 'fileSet',
                        all values in 'filterSet' must exist in 'fileSet'.
                      ''
                      (
                        if isAttrs value then
                          (self // { path = currentPath; }) value
                        else
                          throwIfNot (isBool value) ''
                            '${concatStringsSep "." currentPath}' is not a boolean,
                            all values in 'filterSet' must be boolean.
                          '' value
                      )
                  );
              };

              extend = recursiveUpdate (mapAttrsRecursive (_: _: true) fileSet);

              # function that handles `_defaults` and `_defaultsRecursive` values
              overrideWithDefaults =
                fSet:
                let
                  updateRecursive =
                    path: value:
                    if fSet ? _defaultsRecursive then
                      if elem (last path) specials then value else fSet._defaultsRecursive
                    else
                      value;
                  update = _: value: if isAttrs value then overrideWithDefaults value else fSet._defaults or value;
                in
                removeAttrs (pipe fSet [
                  (mapAttrsRecursive updateRecursive)
                  (mapAttrs update)
                ]) specials;
            in
            pipe filterSet [
              validate
              extend
              overrideWithDefaults
              (flip recursiveUpdate filterSet') # restore filter values
              (filterAttrsRecursive (_: v: isAttrs v || v)) # discard false values
              (mapAttrsRecursive (path: _: getAttrFromPath path fileSet)) # convert to file paths from 'fileSet'
              (collect isPath)
            ];
        };
    };
}
