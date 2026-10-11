import { readdirSync } from 'node:fs';
import { getAgentDir } from '@earendil-works/pi-coding-agent';
import { loadConfig } from '@RUNTIME@/lib/pi/node_modules/@lenard9191/pi-project-profile/config.ts';
import { loadOrDetect, updateUser } from '@RUNTIME@/lib/pi/node_modules/@lenard9191/pi-project-profile/profile/store.ts';
import projectProfile from '@RUNTIME@/lib/pi/node_modules/@lenard9191/pi-project-profile/index.ts';
import { validateModel, planApproved, checkOverrides, approvedProjectProfileApi } from './policy.mjs';

export default function (pi) {
  const child = process.env.PI_DELEGATOR_CHILD === '1';
  pi.on('tool_call', (event, ctx) => {
    if (!child && ['write', 'edit', 'bash', 'delegate', 'codemode', 'run_checks'].includes(event.toolName)
        && !planApproved(ctx.sessionManager.getBranch())) {
      return { block: true, reason: 'Start /plan; review the completed plan and explicitly Implement it before edits, shell or delegation.' };
    }
  });
  pi.on('before_provider_request', (event, ctx) => {
    // Pi logs and swallows thrown extension errors. Exit, not throw, fails closed
    // before unsupported inference; this restriction is not network containment.
    try { validateModel(`${ctx.model?.provider}/${ctx.model?.id}`); }
    catch { console.error('pi: unconfigured model/provider refused (no fallback)'); process.exit(78); }
    const payload = event.payload;
    if (ctx.model.provider === 'openai-codex' && payload && typeof payload === 'object') {
      payload.service_tier = 'default';
    }
    return payload;
  });
  pi.on('session_start', (_event, ctx) => {
    const dir = getAgentDir();
    const { config } = loadConfig(dir);
    const { stored } = loadOrDetect(dir, ctx.cwd, config, undefined);
    const presets = checkOverrides(readdirSync(ctx.cwd));
    updateUser(dir, stored, user => {
      // Seed only absent keys; explicit project-correct /profile overrides survive.
      for (const [key, command] of Object.entries(presets)) {
        if (!Object.hasOwn(user.overrides, key)) user.overrides[key] = command;
      }
    });
    ctx.ui.setStatus('harness-quota-freshness', 'Quota: remaining allowance from last provider observation; unavailable ≠ zero, not a live token-cost estimate.');
  });
  projectProfile(approvedProjectProfileApi(pi, child));
}
