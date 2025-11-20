{ lib, ... }:
let
  flattenMapServicesConfigToList =
    f: loc: config:
    f loc config
    ++ lib.concatLists (
      lib.mapAttrsToList (
        k: v:
        flattenMapServicesConfigToList f (
          loc
          ++ [
            "services"
            k
          ]
        ) v
      ) config.services
    );
in
{
  getWarnings = flattenMapServicesConfigToList (
    loc: config: map (warning: "in ${lib.showOption loc}: ${warning}") config.warnings
  );

  getAssertions = flattenMapServicesConfigToList (
    loc: config:
    map (e: {
      message = "in ${lib.showOption loc}: ${e.message}";
      assertion = e.assertion;
    }) config.assertions
  );
}
