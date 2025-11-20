{ config, lib, ... }:
{
  imports = [ (lib.mkAliasOptionModule [ "synit" "daemon" ] [ "synit" "daemons" "" ]) ];

  options = {
    synit.daemons = lib.mkOption {
      type = with lib.types; lazyAttrsOf deferredModule;
      default = { };
      description = ''
        This module configures Synit daemons.
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
    synit.daemons."" = {
      inherit (config.process) argv;
    };
  };
}
