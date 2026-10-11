import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { test } from 'node:test';

const source = resolve('pkgs/pi-harness/policy.mjs');
test('per-call routing forbids missing, paid, ambiguous and priority selectors', async () => {
  assert.ok(existsSync(source), 'routing safety policy is not implemented');
  const { validateModel, boundedDelegate } = await import(source);
  assert.equal(validateModel('ollama-cloud/glm-5.3'), 'ollama-cloud/glm-5.3');
  assert.equal(validateModel('openai-codex/gpt-6.1-sol'), 'openai-codex/gpt-6.1-sol');
  for (const model of [undefined, 'glm-5.3', 'openai/gpt-6.1-sol', 'anthropic/claude',
                       'openai-codex/gpt-6.1-sol:high', 'ollama-cloud/other']) {
    assert.throws(() => validateModel(model), /configured/);
  }
  let release;
  const blocked = new Promise(resolve => { release = resolve; });
  let received;
  const execute = boundedDelegate(async (...args) => { received = args[1]; await blocked; return 'done'; });
  const one = execute('one', {model:'openai-codex/gpt-6.1-sol', cwd:process.cwd()}, undefined, undefined, {cwd:process.cwd()});
  await assert.rejects(execute('two', {model:'ollama-cloud/glm-5.3'}, undefined, undefined, {cwd:process.cwd()}), /one/);
  assert.equal(received.model, 'openai-codex/gpt-6.1-sol');
  release();
  assert.equal(await one, 'done');
  await assert.rejects(execute('bad', {model:'ollama-cloud/glm-5.3', cwd:'/outside'}, undefined, undefined, {cwd:process.cwd()}), /checkout/);
});

test('stack presets configure real format/build/test and Nix boundary checks', async () => {
  const policy = await import(source);
  assert.equal(typeof policy.checkOverrides, 'function', 'automatic check presets not implemented');
  assert.deepEqual(policy.checkOverrides(['app.csproj']), {
    typecheck:'pi-project-check dotnet-build', lint:'pi-project-check dotnet-format',
    test:'pi-project-check dotnet-test', build:'pi-project-check dotnet-build'
  });
  assert.deepEqual(policy.checkOverrides(['flake.nix']), {
    lint:'pi-project-check nix-lint', typecheck:'pi-project-check nix-eval', build:'pi-project-check nix-build'
  });
  assert.deepEqual(policy.checkOverrides(['readme.md']), {});
});

test('editing requires a real plan extension implementation entry', async () => {
  const policy = await import(source);
  assert.equal(typeof policy.planApproved, 'function', 'plan approval admission not implemented');
  assert.equal(policy.planApproved([]), false);
  assert.equal(policy.planApproved([{type:'custom', customType:'plan-mode-state', data:{latestPlan:'draft'}}]), false);
  assert.equal(policy.planApproved([{type:'custom', customType:'plan-mode-state', data:{activeImplementation:{id:'accepted'}}}]), true);
  assert.equal(policy.planApproved([
    {type:'custom', customType:'plan-mode-state', data:{activeImplementation:{id:'accepted'}}},
    {type:'custom', customType:'plan-mode-state', data:{activeImplementation:null}}
  ]), false);
});
