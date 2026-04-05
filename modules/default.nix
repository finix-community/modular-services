{
  config,
  options,
  pkgs,
  lib,
  ...
}:
let
  portable-lib = import ./portable/lib.nix { inherit lib; };

  modularServiceConfiguration = portable-lib.configure {
    serviceManagerPkgs = pkgs;
    extraRootModules = [
      ./finit/service.nix
    ];
  };
in
{
  imports = [
    ./finit/system.nix
  ];

  options = {
    system.services = lib.mkOption {
      type = lib.types.attrsOf modularServiceConfiguration.serviceSubmodule;
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
