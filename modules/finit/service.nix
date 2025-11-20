{ config, lib, ... }:
{
  imports = [ (lib.mkAliasOptionModule [ "finit" "service" ] [ "finit" "services" "" ]) ];

  options = {
    finit.services = lib.mkOption {
      type = with lib.types; lazyAttrsOf deferredModule;
      default = { };
      description = ''
        This module configures Finit services.
      '';
    };

    # Import this logic into sub-services also.
    # Extends the portable `services` option.
    services = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submoduleWith {
          class = "service";
          modules = [
            ./service.nix
          ];
        }
      );
    };
  };

  config = {
    finit.services."" = {
      command = lib.escapeShellArgs config.process.argv;
    };
  };
}
