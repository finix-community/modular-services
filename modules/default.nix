{
  config,
  options,
  pkgs,
  lib,
  ...
}:
let
  portable-lib = import ./portable/lib.nix { inherit lib; };
in
{
  imports = [
    ./finit/system.nix
    ./synit/system.nix
  ];

  options = {
    system.services = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submoduleWith {
          class = "service";
          modules = [
            ./portable/service.nix
            ./finit/service.nix
            ./synit/service.nix
          ];
          specialArgs = {
            # perhaps: features."systemd" = { };
            inherit pkgs;
          };
        }
      );
      default = { };
      description = ''
        A collection of modular services.
      '';
      visible = "shallow";
    };
  };

  config = {
    assertions = lib.concatLists (
      lib.mapAttrsToList (
        name: cfg: portable-lib.getAssertions (options.system.services.loc ++ [ name ]) cfg
      ) config.system.services
    );

    warnings = lib.concatLists (
      lib.mapAttrsToList (
        name: cfg: portable-lib.getWarnings (options.system.services.loc ++ [ name ]) cfg
      ) config.system.services
    );
  };
}
