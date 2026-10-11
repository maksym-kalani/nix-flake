# Pi 1.1.0 resolves/installs settings.packages before no-* resource filtering.
# Dedicated harness runtime: enforce immutable explicit resources at the API
# boundary, including SDK children, trust bootstrap and interactive /reload.
# Upstream main retains installMissing and offers no declarative-only policy.
''
  core=$out/lib/pi/node_modules/@earendil-works/pi-coding-agent/dist/core
  cp ${./resource-policy.mjs} "$core/harness-resource-policy.mjs"
  printf '\nimport { enforceDeclarativePackages } from "./harness-resource-policy.mjs";\nenforceDeclarativePackages(DefaultPackageManager);\n' >> "$core/package-manager.js"
  printf '\nimport { assertPinnedResource, assertLoaderResources } from "./harness-resource-policy.mjs";\n' >> "$core/resource-loader.js"
  # npm bin and the exported RPC entry use bundles with private unpatched copies.
  # Route those published entry points through the same guarded unbundled API.
  read -r nodeShebang < "$core/../cli.js"
  printf '%s\nimport "../cli.js";\n' "$nodeShebang" > "$core/../bundle/cli.js"
  printf '%s\nimport "../rpc-entry.js";\n' "$nodeShebang" > "$core/../bundle/rpc-entry.js"
  substituteInPlace "$core/resource-loader.js" \
    --replace-fail 'constructor(options) {' 'constructor(options) { assertLoaderResources(options);' \
    --replace-fail 'async reload(options) {' 'async reload(options) { assertLoaderResources(this);' \
    --replace-fail 'async loadCurrentExtensionSet(options) {' 'async loadCurrentExtensionSet(options) { assertLoaderResources(this);' \
    --replace-fail 'extendResources(paths) {' 'extendResources(paths) { for (const entries of Object.values(paths)) { for (const entry of entries ?? []) assertPinnedResource(typeof entry === "string" ? entry : entry.path); }'
''
