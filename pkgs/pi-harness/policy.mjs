import { realpathSync } from 'node:fs';
import { resolve } from 'node:path';

export const MODELS = ['ollama-cloud/glm-5.3', 'openai-codex/gpt-6.1-sol'];

export function validateModel(model) {
  if (!MODELS.includes(model)) throw new Error('Select an exact configured provider/model per call; no fallback');
  return model;
}

export function checkOverrides(files) {
  if (files.some(file => /\.(csproj|sln|slnx)$/.test(file))) return {
    typecheck: 'pi-project-check dotnet-build', lint: 'pi-project-check dotnet-format',
    test: 'pi-project-check dotnet-test', build: 'pi-project-check dotnet-build',
  };
  if (files.includes('flake.nix')) return {
    lint: 'pi-project-check nix-lint', typecheck: 'pi-project-check nix-eval', build: 'pi-project-check nix-build',
  };
  return {};
}

export function planApproved(entries) {
  const latest = entries.findLast(entry => entry.type === 'custom' && entry.customType === 'plan-mode-state');
  return Boolean(latest?.data?.activeImplementation);
}

// Project-profile owns subprocesses outside Pi's tool pipeline. Gate its API
// registrations, not just tool_call, before any automatic/manual execution.
export function approvedProjectProfileApi(pi, child) {
  const allowed = ctx => child || planApproved(ctx.sessionManager.getBranch());
  const reason = 'Explicitly Implement the completed /plan before project checks.';
  const executionHooks = new Set(['before_agent_start', 'tool_result', 'agent_before_settle', 'turn_end']);
  return new Proxy(pi, {
    get(target, key) {
      if (key === 'on') return (event, handler) => target.on(event, (data, ctx) => {
        if (executionHooks.has(event) && !allowed(ctx)) return;
        return handler(data, ctx);
      });
      if (key === 'registerTool') return tool => target.registerTool({...tool,
        execute: (...args) => allowed(args[4]) ? tool.execute(...args) : {
          isError: true, content: [{type:'text', text:reason}], details: undefined,
        },
      });
      if (key === 'registerCommand') return (name, command) => target.registerCommand(name, {...command,
        handler: (args, ctx) => {
          if ((name === 'verify' || (name === 'profile' && args.trim().split(/\s+/)[0] === 'doctor')) && !allowed(ctx)) {
            ctx.ui.notify(reason, 'warning');
            return;
          }
          return command.handler(args, ctx);
        },
      });
      return Reflect.get(target, key);
    },
  });
}

export function boundedDelegate(execute) {
  let active = false;
  return async (id, params, signal, onUpdate, ctx) => {
    validateModel(params.model);
    if (active) throw new Error('Only one delegate may run per checkout');
    if (params.cwd !== undefined) {
      let same = false;
      try { same = realpathSync(resolve(params.cwd)) === realpathSync(ctx.cwd); } catch { /* invalid path is denied */ }
      if (!same) throw new Error('Delegate cwd must be the selected checkout');
    }
    active = true;
    try {
      return await execute(id, params, signal, onUpdate, ctx);
    } finally {
      active = false;
    }
  };
}
