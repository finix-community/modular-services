{
  description = "Support for NixOS modular services in finix";

  outputs = _: {
    nixosModules.default = import ./modules;
  };
}
