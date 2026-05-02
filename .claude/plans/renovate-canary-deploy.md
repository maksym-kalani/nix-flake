# Plan: Renovate + Automated Canary Deploy with Auto-Rollback (aigis)

> Status: **PROPOSED** (not yet implemented as of 2026-05-02)
> Owner: maksym
> Target host: `aigis` (NixOS, Podman containers)

---

## Goal

Automate container image updates on aigis end-to-end: Renovate opens a PR when a new image version is published, aigis itself deploys the change as a *canary* (test activation), watches Gatus health checks, and either persists+merges (green) or rolls back (red) — all with no human in the loop on the green path.

## Non-goals

- Replacing manual `nixos-rebuild switch` for non-Renovate changes.
- Auto-handling **major** version bumps (kept gated behind manual approval).
- Catching slow-burn regressions (>10 min); existing Gatus+ntfy alerts cover the post-merge case.

## Why this approach

- `nix flake check` and sandboxed VM tests **cannot pull container images** (no network in build sandbox), so CI-side runtime validation is impossible.
- The **production host is the only environment** with the right network, secrets, volumes, and adjacent services to validate a container update.
- Recovery is already cheap: NixOS generations + ZFS snapshots + Gatus alerts mean a bad deploy is detectable in minutes and reversible in seconds.
- The right model is therefore **canary on the host with auto-rollback**, not "more CI."

---

## High-level flow

```
Renovate opens PR (Sat early AM)
        │
        ▼
nix flake check passes (CI)
        │
        ▼
aigis systemd timer (Sat morning, 4 firings 30 min apart)
        │
        ▼
deploy-candidate script:
  1. lockfile guard          (no concurrent deploys)
  2. baseline guard          (Gatus must be all-green NOW)
  3. find first PR with green CI + no active cooldown
  4. fetch + checkout PR
  5. nixos-rebuild test       (activate, do NOT set boot default)
  6. wait 90s for containers to start
  7. poll Gatus for 10 min, every 30s
        │
        ├─ all endpoints green for full window
        │       │
        │       ▼
        │   nixos-rebuild switch          (persist, set boot default)
        │   gh pr merge --squash          (auto-merge)
        │   ntfy: "deployed PR #N"
        │
        └─ any endpoint red, or timeout
                │
                ▼
            nixos-rebuild switch --rollback    (back to prior generation)
            gh pr comment "canary failed: <endpoint> red at <time>"
            ntfy: "rolled back PR #N"
            cooldown 24h before retrying same PR
```

---

## Prerequisites (must be done first)

These come from the prior Renovate plan. Without them, there are no PRs to canary.

1. **Audit `:latest` pins**
   ```
   grep -rhE '^\s*image\s*=' hosts/aigis/services/ | sort -u
   ```
   Categorize each image as: pinned-to-version / `:latest` / unpinned.

2. **Pin tags** in every `hosts/aigis/services/*.nix` to a real version (e.g. `:1.2.3`). Renovate cannot bump `:latest`. For images that only ship `:latest`, pin to digest (`@sha256:...`) and let Renovate handle digest bumps via `pinDigests`.

3. **Add `renovate.json`** at repo root:
   ```json
   {
     "$schema": "https://docs.renovatebot.com/renovate-schema.json",
     "extends": ["config:recommended", ":dependencyDashboard"],
     "schedule": ["* 0-6 * * 6"],
     "timezone": "Europe/Warsaw",
     "rebaseWhen": "behind-base-branch",
     "nix": { "enabled": true },
     "customManagers": [
       {
         "customType": "regex",
         "fileMatch": ["^hosts/aigis/services/.*\\.nix$"],
         "matchStrings": [
           "image\\s*=\\s*\"(?<depName>[^\":]+):(?<currentValue>[^\"@]+)(@(?<currentDigest>sha256:[a-f0-9]+))?\""
         ],
         "datasourceTemplate": "docker"
       }
     ],
     "packageRules": [
       {
         "matchDatasources": ["docker"],
         "groupName": "container images",
         "schedule": ["* 0-6 * * 6"]
       },
       {
         "matchDatasources": ["docker"],
         "matchUpdateTypes": ["major"],
         "dependencyDashboardApproval": true
       }
     ]
   }
   ```
   Note: **no `automerge: true`** — aigis owns merge decisions, not Renovate.

4. **Install Mend Renovate GitHub App** on the repo (https://github.com/apps/renovate). Merge the onboarding PR. Verify the Dependency Dashboard issue lists every container image.

5. **Confirm Gatus JSON API contract**:
   ```
   curl http://<aigis-ip>:<gatus-port>/api/v1/endpoints/statuses?page=1
   ```
   Inspect the shape — the canary script depends on the endpoint name + status fields. Expected shape (verify against live response):
   ```json
   [
     { "name": "jellyfin", "group": "", "key": "...",
       "results": [ { "success": true, "timestamp": "2026-05-02T15:00:00Z", ... } ] }
   ]
   ```

6. **Confirm Nix store GC is running** (canary `test` builds generations that need cleaning up). Likely `nix.gc.automatic = true` somewhere; verify.

---

## Components to build

| Component | New / Edit | Path |
|----------|------------|------|
| Canary deploy script | new | `pkgs/aigis-canary-deploy/default.nix` (writeShellApplication) |
| NixOS module (systemd) | new | `hosts/aigis/infra/canary-deploy.nix` |
| Module import | edit | `hosts/aigis/infra/default.nix` |
| Sops secret | new | `secrets/secrets.yaml` → `canary/env` |
| Renovate config | new | `renovate.json` (root) |
| Service tag pins | edit | `hosts/aigis/services/*.nix` (subset) |

---

## Implementation phases

### Phase A — Foundation
Complete prerequisites 1–6 above.
**Exit:** Renovate has opened at least one real bump PR; CI green; baseline Gatus all-healthy.

### Phase B — Canary deploy script
File: `pkgs/aigis-canary-deploy/default.nix`

```nix
{ writeShellApplication, git, gh, jq, curl, gnused, gawk, util-linux, coreutils, nixos-rebuild }:
writeShellApplication {
  name = "aigis-canary-deploy";
  runtimeInputs = [ git gh jq curl gnused gawk util-linux coreutils nixos-rebuild ];
  text = builtins.readFile ./aigis-canary-deploy.sh;
}
```

Sketch of `aigis-canary-deploy.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-/home/maksym/nix-flake}"
LOCK=/var/lib/aigis-canary/lock
COOLDOWN_DIR=/var/lib/aigis-canary/cooldown
WATCH_SECS="${WATCH_SECS:-600}"
POLL_INTERVAL="${POLL_INTERVAL:-30}"
STARTUP_GRACE="${STARTUP_GRACE:-90}"
GATUS_URL="${GATUS_URL:?must be set}"
NTFY_URL="${NTFY_URL:?must be set}"
DRY_RUN="${AIGIS_CANARY_DRY_RUN:-0}"

mkdir -p "$COOLDOWN_DIR" "$(dirname "$LOCK")"

log()    { echo "[canary] $*"; }
notify() { curl -fsS -d "$1" "$NTFY_URL" >/dev/null || true; }

# --- 0. lock ---
exec 9>"$LOCK"
flock -n 9 || { log "another canary is running, exit"; exit 0; }

# --- 1. baseline must be green ---
gatus_status_json() { curl -fsS "$GATUS_URL"; }
gatus_all_green() {
  # Returns 0 if every endpoint's most recent result is success.
  # Adjust jq path once Gatus API shape is verified in Phase A.
  gatus_status_json | jq -e 'all(.[]; .results[-1].success == true)' >/dev/null
}
gatus_first_failing() {
  gatus_status_json | jq -r '[.[] | select(.results[-1].success == false)][0].name // empty'
}

if ! gatus_all_green; then
  log "baseline RED, aborting"; exit 0
fi

# --- 2. find a candidate PR ---
cd "$REPO"
candidate=$(gh pr list --label renovate --state open \
  --json number,headRefName,statusCheckRollup,mergeable \
  --jq '[.[] | select(.mergeable=="MERGEABLE") |
         select(.statusCheckRollup | length == 0 or all(.; .conclusion=="SUCCESS"))] | .[0] // empty')

[ -z "$candidate" ] && { log "no eligible PR"; exit 0; }

num=$(jq -r .number    <<<"$candidate")
branch=$(jq -r .headRefName <<<"$candidate")

# --- 3. cooldown check ---
cd_file="$COOLDOWN_DIR/$num"
if [ -e "$cd_file" ]; then
  age=$(( $(date +%s) - $(stat -c %Y "$cd_file") ))
  if [ "$age" -lt 86400 ]; then
    log "PR #$num in cooldown ($((age/3600))h ago), skip"; exit 0
  fi
fi

log "candidate: PR #$num ($branch)"

if [ "$DRY_RUN" = "1" ]; then
  log "DRY RUN: would checkout, test, watch, then merge or rollback"; exit 0
fi

# --- 4. checkout ---
git fetch origin "$branch:$branch" --force
prev_ref=$(git rev-parse HEAD)
git checkout "$branch"

# --- 5. test-activate ---
notify "canary: starting test deploy of PR #$num"
if ! nixos-rebuild test --flake "$REPO#aigis"; then
  log "test activation FAILED, restoring git ref"
  git checkout "$prev_ref"
  notify "canary: test activation failed for PR #$num"
  touch "$cd_file"
  exit 1
fi

# --- 6. wait + poll ---
sleep "$STARTUP_GRACE"
deadline=$(( $(date +%s) + WATCH_SECS ))

while [ "$(date +%s)" -lt "$deadline" ]; do
  if ! gatus_all_green; then
    failing=$(gatus_first_failing)
    log "endpoint '$failing' RED — rolling back"
    nixos-rebuild switch --rollback
    git checkout "$prev_ref"
    gh pr comment "$num" --body "Canary failed: \`$failing\` reported red at $(date -Is). Auto-rolled back."
    notify "canary: rolled back PR #$num ($failing failed)"
    touch "$cd_file"
    exit 1
  fi
  sleep "$POLL_INTERVAL"
done

# --- 7. green → persist + merge ---
log "watch window passed, persisting"
nixos-rebuild switch --flake "$REPO#aigis"
gh pr merge "$num" --squash --delete-branch
notify "canary: deployed and merged PR #$num"
log "done"
```

**Exit:** script runs to completion in `AIGIS_CANARY_DRY_RUN=1` mode against a real PR.

### Phase C — NixOS module wiring
File: `hosts/aigis/infra/canary-deploy.nix`

```nix
{ pkgs, config, lib, ... }:
let
  canary = pkgs.callPackage ../../../pkgs/aigis-canary-deploy { };
in
{
  systemd.services.aigis-canary-deploy = {
    description = "Canary-deploy a Renovate PR with auto-rollback";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${canary}/bin/aigis-canary-deploy";
      StateDirectory = "aigis-canary";
      EnvironmentFile = config.sops.secrets."canary/env".path;
      # Runs as root; nixos-rebuild needs it.
    };
    path = with pkgs; [ git gh jq curl util-linux coreutils ];
  };

  systemd.timers.aigis-canary-deploy = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      # Saturday morning, 4 attempts in case of transient failures
      OnCalendar = "Sat *-*-* 07:00,07:30,08:00,08:30:00";
      Persistent = true;
    };
  };

  sops.secrets."canary/env" = {
    sopsFile = ../../../secrets/secrets.yaml;
    mode = "0400";
  };
}
```

Edit `hosts/aigis/infra/default.nix` to add `./canary-deploy.nix` to its imports list.

**Exit:** `nix eval .#nixosConfigurations.aigis.config.system.build.toplevel.drvPath` succeeds.

### Phase D — Secrets
Add to `secrets/secrets.yaml` (sops-encrypted) — synthetic example shape:

```
canary/env: |
  GH_TOKEN=<fine-grained-pat-this-repo-only>   # contents:write + pull-requests:write
  NTFY_URL=https://ntfy.sh/<topic-or-local>
  GATUS_URL=http://localhost:<port>/api/v1/endpoints/statuses?page=1
```

**Exit:** secret decrypts on aigis: sops-nix path readable by root.

### Phase E — Renovate config refinement
- Confirm `automerge: false` everywhere — aigis owns merging.
- Add `assignees: ["maksym"]` so PRs are visible.
- Keep `dependencyDashboardApproval: true` for major bumps.

### Phase F — Dry-run validation
1. `nixos-rebuild switch --flake .#aigis` to deploy the script + module.
2. Manually: `sudo AIGIS_CANARY_DRY_RUN=1 systemctl start aigis-canary-deploy`.
3. Inspect `journalctl -u aigis-canary-deploy`.
4. Verify it found a PR, baseline-green check passed, and exited cleanly without doing anything destructive.

### Phase G — Live trial
1. Disable timer first: `systemctl stop aigis-canary-deploy.timer && systemctl disable aigis-canary-deploy.timer` (or omit `wantedBy` initially).
2. Manually run against a real (low-risk) Renovate PR: `sudo systemctl start aigis-canary-deploy`.
3. Watch journal + Gatus + ntfy.
4. After 2–3 successful manual runs, enable the timer.

### Phase H — Observability
- Journal: `journalctl -u aigis-canary-deploy` (already structured).
- ntfy events at every transition (start, success, rollback, error).
- Optional: a Gatus self-check endpoint that pings the canary's last-success-timestamp file so canary failures (not just deploy failures) are alerted.

---

## Open decisions

1. **Watch window length.** 10 min is a default. Pick after reviewing slowest-starting service in Gatus history (likely Immich or matrix-admin).
2. **"Green" definition.** Plan uses "every endpoint's most recent result == success." Gatus already has `failure-threshold = 3` in the template, so `HEALTHY` already means stable — don't add another layer.
3. **Multi-PR queue.** Script processes one PR per timer fire (4 firings on Saturday → up to 4 PRs/week). If queue grows faster, consider batch-merging into a single test branch. Defer.
4. **Major bumps.** Keep gated by Renovate dependency dashboard. Don't auto-canary `postgres:15→16` at 7 AM.
5. **Cooldown duration.** 24h. Renovate may re-push the same PR; cooldown stops the canary from looping on a fundamentally broken bump.
6. **GH PAT scope.** Fine-grained, this repo only, `contents:write` + `pull-requests:write`. Document rotation steps.

## Risks

| Risk | Mitigation |
|------|------------|
| Slow-burn failures (>10 min) merge anyway | Existing Gatus alerts catch them post-merge; manual rollback then. Accept. |
| Canary disrupts services briefly during restart | Saturday 7 AM matches low-usage; document. |
| GH PAT compromise = repo merge access | Fine-grained PAT, scoped to one repo, sops-encrypted, rotate on schedule. |
| Test activation fails to start container (e.g. removed service renamed) | Script catches non-zero exit from `nixos-rebuild test`, restores git ref, notifies. |
| Rollback itself fails | Script exits with CRITICAL ntfy; left for manual recovery. Do not loop. |
| Disk fills with test-build generations | Existing Nix GC handles it; verify before rollout. |
| Gatus API contract changes between versions | Pin Gatus version; add jq schema sanity check at script start. |

## Files-touched checklist

- [ ] `hosts/aigis/services/*.nix` — pin tags (Phase A)
- [ ] `renovate.json` — root (Phase A)
- [ ] `pkgs/aigis-canary-deploy/default.nix` — new (Phase B)
- [ ] `pkgs/aigis-canary-deploy/aigis-canary-deploy.sh` — new (Phase B)
- [ ] `hosts/aigis/infra/canary-deploy.nix` — new (Phase C)
- [ ] `hosts/aigis/infra/default.nix` — add import (Phase C)
- [ ] `secrets/secrets.yaml` — add `canary/env` (Phase D)

## Validation checklist

- [ ] `nix eval .#nixosConfigurations.aigis.config.system.build.toplevel.drvPath` after each Nix edit
- [ ] `sudo nixos-rebuild test --flake .#aigis` once before deploying canary itself
- [ ] Dry-run: `sudo AIGIS_CANARY_DRY_RUN=1 systemctl start aigis-canary-deploy`
- [ ] Manual live run against a low-risk PR
- [ ] Enable timer only after 2–3 successful manual runs

## Recovery / disable kill-switch

If the canary misbehaves:

```
sudo systemctl disable --now aigis-canary-deploy.timer
sudo systemctl stop aigis-canary-deploy.service
sudo nixos-rebuild switch --rollback   # if a bad deploy slipped through
```

Removing the timer leaves the script in place for manual ad-hoc use.

---

## References

- Renovate custom-manager docs: https://docs.renovatebot.com/configuration-options/#custommanagers
- Renovate docker datasource: https://docs.renovatebot.com/modules/datasource/docker/
- NixOS `nixos-rebuild test` semantics: activates the new system but does **not** set the boot default; reboot reverts to the previous generation.
- Gatus REST API: `/api/v1/endpoints/statuses` — endpoint health rollups.
- Existing repo conventions: see `.claude/CLAUDE.md` "Workflow Rules" section (verify-target, prefer-upstream, always-eval).
