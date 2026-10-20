# finix - modular services

Support for [Modular services](https://nixos.org/manual/nixos/unstable/#modular-services) for `finix`.

Services declared under `system.services` are converted into Finit version 5
service stanzas and rendered into `/etc/finit.d/<name>.conf`:

- `process.argv` becomes the stanza's `command`.
- `process.reloadCommand` (or the `process.reloadSignal` derivation) becomes the
  Finit version 5 `exec-reload` used by `initctl reload <service>`.
- `notificationProtocol.systemd` / `notificationProtocol.s6` set the Finit
  version 5 `notify` readiness mechanism.
- Sub-services are siphoned as dash-joined stanzas, e.g. the sub-service
  `reload.inner` of `reload` becomes `reload-inner`.

Inside a service, use `finit.service.*` to configure its own stanza (e.g.
`finit.service.runlevel = "2";`) and `finit.services.<name>.*` for additional
stanzas.

There is a Matrix room for discussions:

- https://matrix.to/#/#modular-services:nixos.org

Relevant links:

- https://github.com/NixOS/nixpkgs/pull/372170
- https://github.com/NixOS/nixpkgs/issues/428084

## Tests

The checks use the compliance suite for modular service integrations from
nixpkgs, with the VM tests driven by the finix upstream test library. Note that
`mkTest` is not part of the finix flake's `lib` output; it lives under
`<finix-input>/tests/lib`:

```shell
nix flake check                 # eval + VM tests for x86_64-linux and aarch64-linux
nix build .#checks.x86_64-linux.eval          # eval-level compliance only
nix build -L .#checks.x86_64-linux.basic-argv # one VM test, with logs
```

The VM tests boot a finix system with Finit as PID 1, start the suite's
services, and reload them via `initctl reload`.
