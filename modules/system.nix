# Finit backend system wiring for Nixpkgs [modular services](https://nixos.org/manual/nixos/unstable/#modular-services).
#
# Mirrors NixOS' `nixos/modules/system/service/systemd/system.nix`: the root
# module defines `system.services` and siphons every root and sub service,
# dash-joined, into Finit's `finit.services` stanzas.
{
  config,
  options,
  lib,
  pkgs,
  ...
}:

let
  portable-lib = import "${pkgs.path}/lib/services/lib.nix" { inherit lib; };
  modularServiceConfiguration = portable-lib.configure {
    serviceManagerPkgs = pkgs;
    extraRootModules = [
      ./service.nix
    ];
  };

  makeServices =
    prefixes: service:
    lib.concatMapAttrs (
      name: module:
      let
        label = if name == "" then prefixes else prefixes ++ [ name ];
      in
      {
        "${lib.concatStringsSep "-" label}" =
          { ... }:
          {
            imports = [ module ];
          };
      }
    ) service.finit.services
    // lib.concatMapAttrs (
      subServiceName: subService: makeServices (prefixes ++ [ subServiceName ]) subService
    ) service.services;
in
{
  _class = "nixos";

  options = {
    system.services = lib.mkOption {
      type = lib.types.attrsOf modularServiceConfiguration.serviceSubmodule;
      default = { };
      description = ''
        A collection of [modular services](https://nixos.org/manual/nixos/unstable/#modular-services) that are configured as Finit services.
      '';
      visible = "shallow";
    };
  };

  # Siphon Finit stanzas for those defined in isolation to the system.
  config = {
    finit.services = lib.concatMapAttrs (
      topLevelName: topLevelService: makeServices [ topLevelName ] topLevelService
    ) config.system.services;

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
