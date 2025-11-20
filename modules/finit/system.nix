{ config, lib, ... }:
let
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
  # Assert Finit services for those defined in isolation to the system.
  config = lib.mkIf config.finit.enable {
    finit.services = lib.concatMapAttrs (
      topLevelName: topLevelService: makeServices [ topLevelName ] topLevelService
    ) config.system.services;
  };
}
