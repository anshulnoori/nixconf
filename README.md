# nixconf

Declarative NixOS and Home Manager configuration for Anshul's physical Linux
devices. The repository uses pinned flakes and a dendritic flake-parts layout.

Repository infrastructure is ready. Host roots and hardware configuration will
be added from each target machine after live inspection.

## Design

- [`docs/repository-design.md`](./docs/repository-design.md) describes module
  boundaries, caching, and update automation.
- [`docs/system-design.md`](./docs/system-design.md) records the confirmed `t1`
  system design and remaining live facts.
- [`docs/application-stack.md`](./docs/application-stack.md) records the planned
  desktop and application stack.
- [`docs/pc-runner-bootstrap.md`](./docs/pc-runner-bootstrap.md) describes the
  non-destructive live-runner bootstrap for `t1`.

## Development

The flake exposes Linux outputs only: `x86_64-linux` and `aarch64-linux`.

```sh
direnv allow
# or
nix develop

nix fmt
nix flake check --all-systems --no-build
```

Local pre-push validation evaluates without realizing host systems. CI builds
and caches the full `t1` closure after each push to `master`. See
[`docs/development.md`](./docs/development.md) for repository conventions and
external setup.
