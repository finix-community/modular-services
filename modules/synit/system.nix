{ config, lib, ... }:
let
  makeDaemons =
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
    ) service.synit.daemons
    // lib.concatMapAttrs (
      subServiceName: subService: makeDaemons (prefixes ++ [ subServiceName ]) subService
    ) service.services;
in
{
  # Assert Synit services for those defined in isolation to the system.
  config = lib.mkIf config.synit.enable {

    synit.daemons = lib.concatMapAttrs (
      topLevelName: topLevelService: makeDaemons [ topLevelName ] topLevelService
    ) config.system.services;
  };

}
