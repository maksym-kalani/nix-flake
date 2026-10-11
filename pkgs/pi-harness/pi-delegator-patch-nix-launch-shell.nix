{ bash }:
''
  # Upstream's privileged launch gate requires sh -p. Nix builders expose a
  # minimal /bin/sh that rejects -p; use the pinned Bash without weakening
  # the gate, process-session capture or cancellation semantics.
  substituteInPlace "$out/lib/pi/node_modules/@mostlyworks/pi-delegator/src/runner.ts" \
    --replace-fail 'spawn("/bin/sh", [' 'spawn("${bash}/bin/bash", ['
''
