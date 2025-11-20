final: prev:

let
  inherit (builtins)
    attrNames
    filter
    getAttr
    listToAttrs
    readDir
    ;

  entries = readDir ../pkgs;
  pkgs =
    entries
    |> attrNames
    |> filter (name: (getAttr name entries) == "directory")
    |> map (name: {
      inherit name;
      value = prev.${name}.overrideAttrs (
        {
          passthru ? { },
          ...
        }:
        {
          passthru = passthru // {
            # TODO: establish a convention on services in passthru.
            #
            # Here a single service is likely being defined but
            # the modular services example has an attrset like:
            # `{ services.default = { config, lib, pkgs, ... }: …; }`
            services.default = import ../pkgs/${name}/service.nix final.${name};
          };
        }
      );
    })
    |> listToAttrs;
in
pkgs
// {
  __toString = _: "${prev.__toString or (_: "nixpkgs") prev}:modular-services";
}
