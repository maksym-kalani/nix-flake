# Personal Pi harness — Belial / #239

Declarative implementation, **not deployment evidence**. Only `home/maksym/belial.nix`
enables `features.piHarness.enable`. Aigis does not import the feature. The existing
Claude Code plugins/hooks, Node and RTK remain in the AI feature; only its raw
`pi-coding-agent` package was replaced with the sandbox launcher. No switch, SSH,
provider inference or modification of an existing API repository is performed.

## Installation and first login

Build the reviewed configuration first; activation remains a separate human decision.
Do not run the whole workstation closure just to validate this feature:

```sh
nix build --no-link -L .#pi-harness .#pi-runtime .#pi-addons .#pi-skills
nix build --no-link -L .#checks.x86_64-linux.pi-home-manager .#checks.x86_64-linux.pi-api
nix eval --raw .#nixosConfigurations.belial.config.system.build.toplevel.drvPath
nix eval --raw .#nixosConfigurations.belial.config.home-manager.users.maksym.home.activationPackage.drvPath
```

After the user installs/activates the reviewed Home Manager configuration, `pi` is
**only the sandboxed entrypoint** in that configuration. There is no same-name raw
Pi package installed alongside it. Check shell aliases and old manually installed
npm binaries with `type -a pi`; remove/shadowing corrections are a human action, not
an automatic deletion of previous software or state.

Use an independent clone, not a linked Git worktree with metadata outside the selected
checkout. Select the repository root, not its parent or a nested directory:

```sh
pi --project "$PWD" -- --approve
# without Home Manager installation:
nix run .#pi-harness -- --project "$PWD" -- --approve
```

`--approve` is Pi's explicit trust of project-local instructions/checks; choose it
only for a reviewed repository. All extensions, model calls and their descendants
remain inside the outer sandbox. Start without it to inspect untrusted content;
verification may then be refused by upstream's project-trust gate.

On first launch the launcher projects settings into
`~/.local/state/pi-harness/checkouts/<SHA256-of-absolute-project-path>/mutable/agent`.
To compute the nonsecret directory name:

```sh
python3 -c 'import hashlib,os; print(hashlib.sha256(os.fsencode(os.getcwd())).hexdigest())'
```

* Ollama Cloud is an API-key provider, **not an OAuth `/login` provider**. Outside the
  sandbox, privately edit that dedicated `agent/auth.json` using the existing key:
  its `ollama-cloud` entry must have `type: "api_key"` and the actual runtime `key`.
  File mode must be `0600`, containing directory `0700`. Never put it in this repo,
  a Nix expression, command-line `--api-key`, logs or the Nix store. The launcher
  neither reads key values nor copies `~/.pi` credentials automatically.
* For Codex, use `/login` → OpenAI Codex inside Pi. Open the displayed URL on the
  host browser and complete OAuth yourself. Auth and refreshed tokens are ordinary
  writable runtime files, not store symlinks. This shared-network mode supports
  loopback callbacks; browser launching is not exposed from inside the sandbox.
* Login/state are checkout-specific. Moving a checkout changes its state identity;
  migration or copying selected auth state is an explicit human action. Existing
  `~/.pi` state is never deleted or migrated automatically.

## Workflow and approval

GLM 5.3 is the default: `ollama-cloud/glm-5.3`. For difficult work explicitly select
`openai-codex/gpt-6.1-sol`. These exact IDs exist in the pinned published catalogs;
account access, subscription allowance and successful inference are **unverified**.

1. Use `/plan` and plan the change with read/grep/find/ls.
2. Review the completed plan in the installed plan extension and explicitly choose
   **Implement**. Merely saying “approved” in a model prompt is not tool admission.
3. Plan retention is `keep`; safety admission reads the real extension's current
   `plan-mode-state.activeImplementation` session entry. Before that exists, native
   write/edit/bash, delegate, codemode and run_checks calls are blocked. Project-profile's
   automatic baseline/read/settle/per-turn hooks and manual verification commands share
   the approval gate, including direct subprocess paths. Clearing the plan closes
   admission again. The guard is a cooperative tool boundary, not hostile-code control.
4. After changes, the project-profile extension runs its automatic checks and at most
   two repair rounds. Inspect `/profile doctor`, `/verify all` and full diagnostic logs;
   unavailable/blocked checks are not success, and existing failures remain visible.

Exactly one dispatcher is installed: `@mostlyworks/pi-delegator@0.6.6`. Every delegate
call must contain an **exact** configured `model`; omission, fuzzy selectors, another
provider/model and thinking/priority suffixes are rejected. At most one delegate runs,
all profiles have a ten-minute deadline, and one outer launcher lock serializes all
harness sessions using the same host state root. This deliberately sacrifices parallel
readers for a simple single-writer guarantee. It does not lock other human editors.

Scout/reviewer have no Bash/edit/write tools. Tester can create test artifacts through
Bash (not an enforced read-only reviewer); worker edits. Children explicitly load all
five skills, Ollama registration, safety admission and project-profile checks despite
upstream's `--no-extensions --no-skills`. They do not load the dispatcher. Trusted project
`.pi/pi-delegator.json` cannot replace the declarative child profiles. Child trust is
admitted only after parent plan approval; no recursive dispatcher or schedules exist.

Unsupported Pi inference providers fail closed by terminating the session before the
request; throwing an extension error is insufficient because upstream logs/swallow it.
Codex request `service_tier` is set to `default`. There is no paid/Claude/priority fallback.
This does not prevent arbitrary approved Bash or malicious extensions making HTTP calls.

## Checks and runtime prerequisites

`features.piHarness.extraTools` admits explicitly chosen project runtimes into the
sandbox tool path (e.g. `[ pkgs.dotnet-sdk_10 ]` for a compatible project). It is empty
by default: no new global SDK, inherited host PATH or implicit `nix develop` evaluation.
Choose a SDK matching the project's `global.json`; realize dependencies/dev tooling
outside the sandbox first, never expose the Nix daemon to bypass this boundary.

For root .NET projects the automatic presets run:

* `dotnet build --no-restore -p:RunAnalyzersDuringBuild=true -warnaserror`
* `dotnet format --no-restore --verify-no-changes`
* VSTest: `dotnet test --no-restore --no-build`

Use `/profile set <tier> <command>` for solution/nested-project overrides. For native
MTP create reviewed `.pi/checks.json`, with `testRunner: "mtp"` and an explicit
`testCommand` **argv array** for the existing runner/project; no framework is installed
or replaced. MTP without a command fails closed rather than guessing VSTest switches.
For example an existing self-hosted MTP project may use `dotnet run --project ...
--no-build -- ...`; modern `dotnet test` MTP/global.json projects need their own supported
solution/project arguments. Set `testRunner` explicitly when automatic detection is
ambiguous. Check commands can execute project code and require repository trust.

Enabled analyzers must actually be configured by the project/.editorconfig. The
harness requests their execution; it does not invent a security-analyzer baseline or
claim green coverage when a check has not run. `tests/pi/fixtures/api` is a disposable
.NET 10 minimal API, built-in .NET analyzers and empty NuGet sources, not an empty test
fixture or a replacement for existing xUnit/NUnit/MTP projects. `pi-api` performs real
HTTP health/greeting/validation/create/read/delete/not-found acceptance and cleans up
its server. It does **not** test a database, WebApplicationFactory or Testcontainers.

Nix presets run `nixfmt --check` and `statix check`. Eval/build checks explicitly return
BLOCKED in the ordinary sandbox: store mounts are read-only and no daemon is forwarded.
For the separate outside-sandbox human workflow configure **relevant targets only**:

```json
{
  "nixEvalTargets": ["nixosConfigurations.belial.config.home-manager.users.maksym.home.activationPackage.drvPath"],
  "nixBuildTargets": ["pi-harness", "checks.x86_64-linux.pi-home-manager"]
}
```

Then run the reviewed `check_runner.py nix-eval` / `nix-build` outside Pi. They use
`--offline --no-write-lock-file`, never `switch`, sudo or activation. Full workstation
builds and project dependency restores are not implicit checks.

## Declarative versus mutable

`pkgs/pi-harness/npm/package-lock.json` locks the real npm tarballs/integrities and
transitive dependencies. `buildNpmPackage` installs that tree offline from a Nix
fixed-output dependency cache with lifecycle/rebuild scripts disabled. Runtime assets
come from published Pi, not a source build requiring model-catalog downloads. Pi and
addons share one locked Node tree: `pi-runtime` and `pi-addons` name the same derivation.
No runtime `pi install`, npm-global installation, git pull or activation download occurs.
The dedicated package-manager/resource-loader patch rejects ambient package sources
before resolution, ignores mutable resource overrides, permits only explicit immutable
store resources, and blocks installer/update/remove/Git-refresh operations. Bundled
CLI/RPC entry points route through the same guarded API; `/reload` cannot bootstrap
project-owned packages. Real intercepted-installer regressions verify this without
performing downloads. This is Pi resource policy, not an approved-Bash network firewall.

Pinned versions: Pi **1.1.0**, Ollama **0.13.0**, quota **0.3.0**, plan **0.59.2**,
project-profile **1.3.0**, delegator **0.6.6**. npmDepsHash:
`sha256-08XG9jm1yrdfowdF9nBMkhuJ8vmzUkFIIiXmcYy/ryI=`. Node comes from the unchanged
nixpkgs lock (`nodejs_24`, evaluated 24.21.0). No flake inputs were updated.
Upstream's Pi 1.1.0 loader supplies compatibility aliases for old `@mariozechner/*`
and `@sinclair/typebox` imports; real addon factory loads verify compatibility rather
than installing duplicate peer cores with a different namespace.

Ready skills are complete directory snapshots fetched by revision and hash in
`skills.nix`, including support files and upstream licenses:

| Repository | Revision | Skills |
|---|---|---|
| dotnet/skills | `1d40f95ed0f2cdedfa4c9b2614b7c2035a4323cb` | dotnet-webapi, run-tests |
| StefanTheCode/dotnet-ai-toolkit | `77af4c1ac3fb5fe165a049fe22011ac17a27f457` | integration-test-setup |
| olafkfreund/nix-skills | `f5c8e8b3b3255e323e5b84192d0b6ed2e79ef4f4` | nix-workflow, nixos-operations |

Optional upstream home-manager remains off unless `includeHomeManager = true`. No new
custom SKILL.md/domain bundle is generated. Delegator prompts are its published
Markdown files; the parent workflow prompt and safety glue are intentionally small.

On every launch managed keys are atomically projected into regular `0600` writable
settings files. Unmanaged keys, auth, sessions and addon state are preserved; managed
provider/model/resources/delegator policies are reconciled. Malformed managed JSON or
symlinked settings fail closed. `/login`, `/model`, extension settings and OAuth refresh
can write; security-managed keys return to declarative values at the next launch.

Quota addons scope observations to the **active** provider. Codex uses OAuth quota
polling, no estimated fallback. A minimal formatting patch changes Ollama's upstream
used-percent bar to explicitly labeled **remaining** percentages derived from its validated
`/api/balance` readings; warning thresholds and active-provider polling are unchanged.
`/ollama-cloud-usage` additionally reports the actual remaining monetary allowance where
supplied. Missing readings are never presented as a false zero. The safety status labels
values as last provider observations:
Ollama refreshes every five minutes, Codex about every minute, unavailable is not zero.
Failed/quota-stale data and suspicious Codex reconciliation are upstream limitations;
no account data was fetched here, and this is not a guaranteed live remaining-token meter.

## Sandbox threat model and integration-test boundary

The launcher uses Bubblewrap for the whole process, including plugins and subprocesses:
new user/PID/mount/IPC/UTS/cgroup namespaces, dropped capabilities, disabled nested user
namespaces, `--new-session`, `--die-with-parent`, read-only root/store/tool tree and minimal
synthetic HOME. Only the selected `/project`, dedicated `/state` and disposable `/tmp`
are writable. State includes auth/session/addon caches, NuGet and .NET caches. Host home,
SSH/GPG agents, DBus, Docker/Podman and Nix daemon sockets, sudo/system services and host
mutation paths are not bound. Environment is a small explicit allowlist; existing Unix
sockets under project/state are refused. Canonical symlink roots, external `.git` linked
worktrees/shared objects and roots overlapping protected/state paths are rejected.
Subtree symlinks cannot reach unmounted host files. Concurrent hostile host filesystem
mutation is outside this personal single-user boundary; it is not a hardened multi-user
service or a kernel-exploit defense. Nix store contents are public and readable.

**Connected mode shares the network namespace.** Model/OAuth traffic, other outbound
traffic and host/LAN TCP services are reachable. No egress allowlist or loopback isolation
is claimed; malicious code can exfiltrate selected project files and the dedicated auth
state it necessarily reads. Keep projects free of unrelated secrets, disable unauthenticated
management TCP endpoints, and use a separate VM for stronger network/credential separation.
`--offline` adds a network namespace for local checks; model requests/login cannot work.
Ollama web tools are hard-disabled with `PI_OLLAMA_WEB_TOOLS=0` in parent and children.

Testcontainers is **blocked in the ordinary sandbox**. A separate disposable VM/container
runtime, test-only data, an isolated daemon and scoped project transfer must be explicitly
provisioned by a human. Do not forward the host Docker socket or use the model network
exception to reach a host daemon over TCP. No isolated database runtime is provisioned or
validated by this change; ordinary unit/in-process API tests need no daemon.

Native Codemode is off by default. For an explicit A/B trial, load `builtin:codemode`
and `--tools +codemode` after reviewing a plan. No toggle addon, classifier or new billing
provider is installed. Compare accepted results, retries, parent+child quota, latency and
human corrections; no performance claim is made by this implementation.

## Reproducible verification / known blockers

`nix develop .#pi-harness` supplies Python/Node/nixfmt/statix/ruff for local tests.
`tests/pi/evidence/` preserves real RED/GREEN tracer logs and execution attempts.
`checks.pi-harness` tests state preservation/path admission/check argv/model admission,
real addon/skill loads, declarative project-profile protection and real credential-free
child launch/model selection. The check passes in the Nix builder as well as locally.
The original subprocess failure was reproduced: Nix's minimal `/bin/sh` rejects
upstream's `-p` launch-gate flag and closes stdin (`EPIPE`). Current upstream still
hardcodes `/bin/sh`; the separate `pi-delegator-patch-nix-launch-shell.nix` packaging
patch selects pinned Bash without changing gate flags or cleanup semantics. The real
both-model subprocess test catches the regression; no error is converted into a skip.
`pi-api` and `pi-home-manager` are separate focused successful derivations.

```sh
nix build --no-link -L .#checks.x86_64-linux.pi-harness
nix run .#pi-sandbox-acceptance
nix build --no-link -L .#checks.x86_64-linux.pi-sandbox-vm
```

Local LXC Bubblewrap acceptance is BLOCKED (`cannot open /proc/sys/user/max_user_namespaces:
Read-only file system`), not sandbox enforcement proof. The VM check and pinned GitHub
workflow provide a reproducible non-LXC acceptance path; VM execution/CI have not been
run here. There is no unsandboxed fallback. Namespace acceptance checks actual namespace
identities, outside-home symlink/sentinel denial, writable scope and descendants.

Standalone `homeConfigurations."maksym@belial"` has the pre-existing Stylix/vicinae error
at the base revision; it is not repaired in #239. Integrated Belial HM and Pi-only HM
are evaluated instead. No provider/OAuth/quota E2E, live terminal behavior, Testcontainers
or Belial deployment is claimed. Initial HM check mistakenly retained a drvPath dependency
context and fetched large documentation build dependencies; the corrected opt-in check
discards that context and dry-run proves its bounded dependency set. Local remaining
capacity and the failed check attempts are retained in evidence, not hidden as success.
