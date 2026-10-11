import assert from 'node:assert/strict';
import { test } from 'node:test';
import { pathToFileURL } from 'node:url';

const nm = process.env.PI_TEST_RUNTIME + '/lib/pi/node_modules';
const { createJiti } = await import(pathToFileURL(nm + '/jiti/lib/jiti.mjs'));
const { formatUsageStatusColored } = await createJiti(import.meta.url).import(nm + '/pi-ollama-cloud/usage.ts');
const theme = { fg: (_color, text) => text };

test('Ollama footer labels actual API remaining percentages rather than usage or token-cost estimates', () => {
  // Contract fixture only; no account requests or fabricated live readings.
  const text = formatUsageStatusColored(theme, {
    included: {
      session: { remaining_percent: 72 },
      weekly: { remaining_percent: 18 },
    },
  });
  assert.match(text, /5h .*72% remaining/);
  assert.match(text, /7d .*18% remaining/);
  assert.equal(formatUsageStatusColored(theme, {}), '', 'missing quota must not become a false zero');
});
