{
  description = "Support for NixOS modular services in finix";

  outputs = _: {
    nixosModules.default = import ./modules;
    overlays.default = import ./overlays/default.nix;
  };
}
