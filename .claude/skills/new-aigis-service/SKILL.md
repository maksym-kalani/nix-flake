---
name: new-aigis-service
description: Scaffold a new self-hosted service on the aigis host. Generates the service file from the app or container template, registers the import in services/default.nix, adds a Caddy reverse-proxy entry to infra/caddy.nix, and validates with nix flake check. Use when the user asks to add a new service to aigis.
disable-model-invocation: true
---

# Add a new service to aigis

Aigis services follow a strict four-point pattern: a file under `hosts/aigis/services/`, an import in `services/default.nix`, a firewall port and gatus endpoint inside the service file, and a Caddy reverse-proxy entry in `infra/caddy.nix`. This skill scaffolds all of it from the templates.

## Required arguments

Ask the user (in one batched question) for any not provided:

- **name** — short slug, becomes the filename and Caddy subdomain (`<name>.laufin.xyz`). Lowercase, hyphenated.
- **kind** — `app` (native NixOS service) or `container` (OCI/Podman). Default: `container` if the user mentions a Docker image, else ask.
- **port** — host-facing TCP port. Must be unique across `hosts/aigis/services/*.nix` — grep before assigning.
- **image** — container image (only for `kind=container`).
- **public** — `yes`/`no` for whether to add a Caddy entry. Default: `yes`.

## Steps

1. **Verify port is free.** Grep `hosts/aigis/services/` and `hosts/aigis/infra/caddy.nix` for the chosen port. If taken, stop and ask for a different port.

2. **Copy the template.** Read `hosts/aigis/templates/app.nix` or `hosts/aigis/templates/container.nix`. Write the new file to `hosts/aigis/services/<name>.nix` with:
   - `name` and `port` substituted in the `let` block
   - For containers: `image`, `port.internal`/`port.external`, and a sensible `volumes` entry (`${appdata}${cfg.name}:/config` is the usual default — confirm with the user if unclear)
   - The gatus endpoint left as the template provides it (URL auto-derived from `name`/`port`)

3. **Register the import.** Edit `hosts/aigis/services/default.nix` and insert `./<name>.nix` into the `imports` list, keeping it adjacent to existing alphabetical neighbors.

4. **Add Caddy entry** (skip if `public=no`). Edit `hosts/aigis/infra/caddy.nix` and append a block before the closing `}` of the `*.laufin.xyz` site:

   ```
   @<name> host <name>.laufin.xyz
   handle @<name> {
     reverse_proxy http://192.168.2.50:<port>
   }
   ```

5. **Validate.** Run `nix flake check --no-build --show-trace` from the repo root. Report any eval errors. Per CLAUDE.md, this is the minimum bar — surface failures, do not claim success without it.

6. **Report.** List the four files touched and remind the user to:
   - Commit the change
   - Run `sudo nixos-rebuild switch --flake .#aigis` on aigis itself
   - Verify the gatus endpoint goes green at `https://gatus.laufin.xyz`

## Notes

- The aigis host IP is `192.168.2.50` and the appdata root is `/var/lib/containers/`. These are encoded in the templates — don't override unless the user asks.
- Secrets (env vars, API keys) go through SOPS — see `hosts/common/secrets.nix` and `secrets/secrets.yaml`. If the service needs a secret, stop and confirm with the user before touching SOPS files (the PreToolUse hook will block direct yaml edits anyway).
- If the service needs a non-standard health-check path, edit the gatus `conditions` block — but `[STATUS] == 200` against the root path covers most webapps.
