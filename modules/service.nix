# Finit backend for Nixpkgs [modular services](https://nixos.org/manual/nixos/unstable/#modular-services).
#
# Loaded into every root and sub service (see ./system.nix), it derives the
# service's own Finit stanza (`finit.services.""`) and extends sub-services
# with itself.
{ config, lib, ... }:
{
  imports = [
    # Escape hatch for configuring this service's own stanza without knowing
    # the `""` naming convention, cf. `systemd.service` in NixOS.
    (lib.mkAliasOptionModule [ "finit" "service" ] [ "finit" "services" "" ])
  ];

  options = {
    finit.services = lib.mkOption {
      type = with lib.types; lazyAttrsOf deferredModule;
      default = { };
      description = ''
        This module configures Finit [services][], with the notable difference
        that their names are prefixed with the abstract service name.

        This option's value is not suitable for reading, but you can define a
        module here that interacts with just the stanza configuration in the
        host system configuration.

        Note that this option contains _deferred_ modules.
        This means that the module has not been combined with the system configuration yet, no values can be read from this option.
        What you can do instead is define a module that reads from the module arguments (such as `config`) that are available when the module is merged into the system configuration.

        The service's own stanza is keyed `""`; its name is derived from the
        abstract service name (and sub-service path) by the containing module.

        [services]: https://finit-project.github.io/config/services/
      '';
    };

    finit.command = lib.mkOption {
      type = lib.types.str;
      default = lib.escapeShellArgs config.process.argv;
      defaultText = lib.literalExpression "lib.escapeShellArgs config.process.argv";
      description = ''
        Starting command for the service's Finit stanza.

        This option sets the primary starting entry, and is the way to
        override the command line derived from {option}`process.argv`.

        By default, it is set to `lib.escapeShellArgs {option}process.argv`.
        Because {option}`process.argv` is already a command line (not an
        argument list), it is used verbatim so that references like `$MAINPID`
        are preserved.

        To override or extend the derived command line, set this option to the
        desired command line:
        ```nix
        finit.command = "''${lib.getExe' pkgs.hello "hello"} --greeting hi";
        ```
      '';
    };

    finit.exec-reload = lib.mkOption {
      type = with lib.types; nullOr str;
      default = config.process.reloadCommand;
      defaultText = lib.literalExpression "config.process.reloadCommand";
      description = ''
        Reload command for the service's Finit stanza (Finit version 5
        `exec-reload`, cf. `systemd.mainExecReload`).

        This option sets the primary reload entry, and is the way to override
        the reload command derived from {option}`process.reloadCommand`.

        By default, it is set to {option}`process.reloadCommand`. Because
        {option}`process.reloadCommand` is already a command line (not an
        argument list), it is used verbatim so that references like `$MAINPID`
        are preserved. When it is unset (or set to `null`), no `exec-reload`
        is emitted and Finit's default reload behavior (`SIGHUP` to the main
        process) applies.

        To override or extend the derived reload command, set this option to
        the desired command line:
        ```nix
        finit.exec-reload = "kill -HUP $MAINPID";
        ```
      '';
    };

    services = lib.mkOption {
      type =
        with lib.types;
        attrsOf (submoduleWith {
          class = "service";
          modules = [
            ./service.nix
          ];
        });
      visible = false;
    };
  };

  config = {
    finit.services."" = {
      conditions = [ "service/syslogd/ready" ];
      command = config.finit.command;
      notify = lib.mkDefault (
        if config.notificationProtocol.systemd then
          "systemd"
        else if config.notificationProtocol.s6 then
          "s6"
        else
          null
      );

      # Finit version 5 reload command, used by `initctl reload <service>`
      # during reconfiguration; null → Finit's default reload behavior
      # (`SIGHUP` to the main process).
      exec-reload = config.finit.exec-reload;
    };
  };
}
