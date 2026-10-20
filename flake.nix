{
  description = "Support for Modular services in finix";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    finix.url = "github:finix-community/finix";
  };

  outputs =
    inputs@{
      self,
      ...
    }:
    let
      finixSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllFinixSystems =
        f:
        inputs.nixpkgs.lib.genAttrs finixSystems (
          system:
          let
            pkgs = import inputs.nixpkgs { inherit system; };
          in
          f pkgs system
        );
    in
    {
      nixosModules.default = import ./modules/system.nix;
      checks = forAllFinixSystems (
        pkgs: system:
        let
          inherit (pkgs) lib;

          testLib = import "${inputs.finix}/tests/lib" {
            pkgs = pkgs.extend (
              _final: prev: {
                runCommand =
                  name: attrs: body:
                  prev.runCommand name (removeAttrs attrs [ "preferLocalBuild" ]) body;
              }
            );
            inherit lib;
          };

        in
        pkgs.testers.modularServiceCompliance {
          callReload = path: "initctl reload ${lib.concatStringsSep "-" path}";
          sharedDir = "/tmp/modular-service-compliance";
          evalConfig =
            { services, ... }:
            let
              machine = inputs.finix.lib.finixSystem {
                inherit (pkgs) lib;
                modules = [
                  {
                    imports = [ inputs.finix.nixosModules.getty ];
                    services.getty.enable = true;
                    nixpkgs.pkgs = lib.mkDefault pkgs;
                    system.services = services;
                  }
                  self.nixosModules.default
                ];
              };
            in
            {
              config = machine.config.system.services;
              checkDrv = machine.config.system.build.toplevel;
            };
          mkTest =
            {
              name,
              services,
              testExe,
            }:
            testLib.mkTest {
              inherit name;
              nodes.machine = {
                imports = [ self.nixosModules.default ];
                system.services = services;

                # Minimal boot services, mirroring the finix upstream tests.
                services.mdevd.enable = true;
                services.getty.enable = true;
              };
              testScript = ''
                machine.start()
                machine.wait_for_console_text("entering runlevel 2")
                machine.succeed("${testExe}")
              '';
            };
        }
      );
    };
}
