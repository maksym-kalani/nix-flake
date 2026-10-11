''
  # Keep upstream /api/balance validation, active-provider polling and warning
  # thresholds; render its percentage as remaining allowance, not spent quota.
  substituteInPlace "$out/lib/pi/node_modules/pi-ollama-cloud/usage.ts" \
    --replace-fail '`''${label} ''${quotaBar(pct)} ''${pct}%`' \
      '`''${label} ''${quotaBar(100 - pct)} ''${100 - pct}% remaining`'
''
