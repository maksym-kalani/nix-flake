import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, readFileSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { test } from 'node:test';

const runtime = process.env.PI_TEST_RUNTIME;
assert.ok(runtime, 'PI_TEST_RUNTIME must be the realized Nix runtime');
const nm = runtime + '/lib/pi/node_modules';
const loader = await import(pathToFileURL(nm + '/@earendil-works/pi-coding-agent/dist/core/extensions/loader.js'));
const temp = mkdtempSync(join(tmpdir(), 'pi-runtime-test-'));
process.env.PI_CODING_AGENT_DIR = temp;
process.env.PI_OLLAMA_WEB_TOOLS = '0';
process.env.PI_TELEMETRY = '0';
const packages = ['pi-ollama-cloud', 'pi-quota-status', '@narumitw/pi-plan-mode',
                  '@lenard9191/pi-project-profile', '@mostlyworks/pi-delegator'];
const paths = packages.flatMap(name => {
  const manifest = JSON.parse(readFileSync(join(nm, name, 'package.json')));
  return manifest.pi.extensions.map(p => join(nm, name, p));
});

test('published baseline addons load in real Pi 1.1.0 Node loader', async () => {
  const loaded = await loader.loadExtensions(paths, temp);
  assert.deepEqual(loaded.errors, []);
  assert.equal(loaded.extensions.length, 5);
  const commands = loaded.extensions.flatMap(extension => [...extension.commands.keys()]);
  assert.ok(commands.includes('plan'));
  assert.ok(commands.includes('verify'));
  assert.ok(commands.includes('quota'));
  assert.ok(!commands.includes('ollama-webtools'));
  assert.ok(loaded.runtime.pendingProviderRegistrations.some(provider => provider.name === 'ollama-cloud'));
});

test('real SDK selects the per-call child model instead of parent model without auth or inference', async () => {
  const sdk = await import(pathToFileURL(nm + '/@earendil-works/pi-coding-agent/dist/index.js'));
  const ai = await import(pathToFileURL(nm + '/@earendil-works/pi-ai/dist/compat.js'));
  const codex = ai.getModel('openai-codex', 'gpt-6.1-sol');
  assert.ok(codex);
  assert.equal(codex.provider, 'openai-codex');
  const resources = new sdk.DefaultResourceLoader({cwd:temp, agentDir:temp, noExtensions:true,
    noSkills:true, noPromptTemplates:true, additionalExtensionPaths:paths.slice(0,1)});
  await resources.reload();
  const {session} = await sdk.createAgentSession({cwd:temp, agentDir:temp, model:codex,
    resourceLoader:resources, sessionManager:sdk.SessionManager.inMemory(temp)});
  assert.equal(session.model.id, 'gpt-6.1-sol');
  assert.equal(session.model.provider, 'openai-codex');
  await session.dispose();
});

test('declarative dispatcher resources resist trusted project removal of safety/deadline profiles', async () => {
  const cfg = JSON.parse(readFileSync(process.env.PI_TEST_CONFIG));
  const templates = JSON.parse(readFileSync(cfg.template));
  for (const [name, value] of Object.entries(templates)) {
    const path = join(temp, name);
    mkdirSync(join(path, '..'), {recursive:true});
    writeFileSync(path, JSON.stringify(value));
  }
  mkdirSync(join(temp, '.pi'), {recursive:true});
  writeFileSync(join(temp, '.pi/pi-delegator.json'), '{"profiles":{"worker":null}}');
  const loaded = await loader.loadExtensions([process.env.PI_TEST_SAFETY + '/delegator.ts'], temp);
  assert.deepEqual(loaded.errors, []);
  const extension = loaded.extensions[0];
  for (const handler of extension.handlers.get('session_start')) {
    await handler({}, {cwd:temp, isProjectTrusted:() => true});
  }
  const tool = extension.tools.get('delegate').definition;
  assert.ok(JSON.stringify(tool.parameters).includes('worker'), 'project removed the declarative writer profile');
  const sdk = await import(pathToFileURL(nm + '/@earendil-works/pi-coding-agent/dist/index.js'));
  const worker = templates['pi-delegator.json'].profiles.worker;
  assert.equal(worker.deadlineMs, 600000);
  assert.equal(worker.model, null);
  assert.equal(worker.skills.length, 5);
  assert.ok(worker.extensions.some(extension => extension.endsWith('pi-ollama-cloud/index.ts')));
  assert.ok(worker.extensions.some(extension => extension.endsWith('/safety.ts')));
  const resources = new sdk.DefaultResourceLoader({cwd:temp, agentDir:temp, noExtensions:true,
    noSkills:true, noPromptTemplates:true, additionalExtensionPaths:worker.extensions,
    additionalSkillPaths:worker.skills});
  await resources.reload();
  assert.deepEqual(resources.getExtensions().errors, []);
  assert.equal(resources.getSkills().skills.length, 5);
  assert.ok(!resources.getExtensions().extensions.some(extension => extension.path.endsWith('/delegator.ts')));
});

test('real delegator subprocess selects each configured model and fails honestly without credentials', async () => {
  const jitiModule = await import(pathToFileURL(nm + '/jiti/lib/jiti.mjs'));
  const jiti = jitiModule.createJiti(import.meta.url, {moduleCache:false, alias:{
    '@earendil-works/pi-coding-agent':nm + '/@earendil-works/pi-coding-agent/dist/index.js'
  }});
  const {runDelegate} = await jiti.import(nm + '/@mostlyworks/pi-delegator/src/runner.ts');
  const worker = JSON.parse(readFileSync(JSON.parse(readFileSync(process.env.PI_TEST_CONFIG)).template))['pi-delegator.json'].profiles.scout;
  const profile = {...worker, name:'scout', timeoutMs:worker.deadlineMs, systemPrompt:readFileSync(worker.prompt,'utf8')};
  for (const model of ['ollama-cloud/glm-5.3', 'openai-codex/gpt-6.1-sol']) {
    const result = await runDelegate({profile, task:'Reply OK only', cwd:temp, model,
      env:{HOME:temp, PATH:process.env.PATH, TMPDIR:process.env.TMPDIR || tmpdir(),
        PI_CODING_AGENT_DIR:temp, PI_OFFLINE:'1', PI_TELEMETRY:'0', PI_OLLAMA_WEB_TOOLS:'0',
        PI_DELEGATOR_PI_BINARY:runtime + '/bin/pi-internal'}, timeoutMs:20000});
    assert.equal(result.ok, false);
    assert.match(result.message + result.stderr, new RegExp('No API key found for ' + model.split('/')[0]));
    assert.equal(result.nativeUsage.totalTokens, 0);
    assert.equal(result.cleanup.processExited, true);
    assert.equal(result.cleanup.pipesClosed, true);
  }
});

process.on('exit', () => rmSync(temp, {recursive:true, force:true}));
