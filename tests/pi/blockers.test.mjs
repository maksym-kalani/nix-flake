import assert from 'node:assert/strict';
import { existsSync, mkdtempSync, mkdirSync, readFileSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';
import { test } from 'node:test';

const runtime = process.env.PI_TEST_RUNTIME;
assert.ok(runtime);
const nm = runtime + '/lib/pi/node_modules';
const sdk = await import(pathToFileURL(nm + '/@earendil-works/pi-coding-agent/dist/index.js'));
const loader = await import(pathToFileURL(nm + '/@earendil-works/pi-coding-agent/dist/core/extensions/loader.js'));
const { DefaultPackageManager } = await import(pathToFileURL(nm + '/@earendil-works/pi-coding-agent/dist/core/package-manager.js'));
const cfg = JSON.parse(readFileSync(process.env.PI_TEST_CONFIG));
const root = mkdtempSync(join(tmpdir(), 'pi-blockers-'));
process.env.PI_OLLAMA_WEB_TOOLS = '0';
process.env.PI_TELEMETRY = '0';

async function profileFixture(child = false, withPlan = false) {
  const dir = mkdtempSync(join(root, 'profile-'));
  const agent = join(dir, 'agent');
  const cwd = join(dir, 'project');
  mkdirSync(agent); mkdirSync(cwd);
  writeFileSync(join(cwd, 'package.json'), '{"name":"canary","scripts":{"typecheck":"node canary.cjs"}}');
  writeFileSync(join(cwd, 'canary.cjs'), "require('node:fs').writeFileSync('CANARY', 'ran')");
  writeFileSync(join(cwd, 'source.ts'), 'export const value = 1;');
  mkdirSync(join(agent, 'project-profile'));
  writeFileSync(join(agent, 'project-profile/config.json'), JSON.stringify({verify:{enabled:true,perTurn:true,headless:true,runTests:'allow',runBuild:'allow'}}));
  process.env.PI_CODING_AGENT_DIR = agent;
  writeFileSync(join(agent,'pi-plan-mode.json'),JSON.stringify({thinkingLevel:'inherit',implementationPlanRetention:'keep'}));
  if (child) process.env.PI_DELEGATOR_CHILD = '1'; else delete process.env.PI_DELEGATOR_CHILD;
  // Use the current admission source with the actual pinned upstream addon.
  const admission = join(dir, 'safety.ts');
  writeFileSync(admission, readFileSync(process.env.PI_TEST_ADMISSION_SOURCE || 'pkgs/pi-harness/safety.ts','utf8').replaceAll('@RUNTIME@', runtime));
  writeFileSync(join(dir, 'policy.mjs'), readFileSync('pkgs/pi-harness/policy.mjs'));
  const paths = cfg.extensions.filter(p => p.endsWith('/safety.ts') || p.includes('/pi-project-profile/') || (withPlan && p.includes('/pi-plan-mode/')))
    .map(p => p.endsWith('/safety.ts') ? admission : p);
  const loaded = await loader.loadExtensions(paths, cwd);
  assert.deepEqual(loaded.errors, []);
  loaded.runtime.sendMessage = () => {};
  // Transport is deliberately inert: exercise upstream plan transitions, never inference.
  loaded.runtime.sendUserMessage = () => {};
  const branch = [];
  loaded.runtime.appendEntry = (customType, data) => branch.push({type:'custom',customType,data:structuredClone(data)});
  loaded.runtime.getActiveTools = () => ['read','bash','edit','write','plan_mode_question','plan_mode_complete'];
  loaded.runtime.getAllTools = () => loaded.runtime.getActiveTools().map(name=>({name,description:name}));
  loaded.runtime.getSettings = () => ({});
  loaded.runtime.getThinkingLevel = () => 'medium';
  loaded.runtime.setThinkingLevel = () => {};
  loaded.runtime.setActiveTools = () => {};
  const notifications=[];
  const ctx = {cwd,mode:'print',hasUI:false,isProjectTrusted:()=>true,
    sessionManager:{getBranch:()=>branch,getEntries:()=>branch,getSessionId:()=>dir,getSessionFile:()=>undefined},
    ui:{setStatus(){},notify(...args){notifications.push(args);},setWidget(){}},isIdle:()=>true};
  async function emit(name, event = {}) {
    for (const extension of loaded.extensions) {
      for (const handler of extension.handlers.get(name) || []) await handler(event, ctx);
    }
  }
  await emit('session_start');
  const profile = loaded.extensions.flatMap(e => [...e.commands.entries()]).find(([name]) => name === 'profile')[1];
  await profile.handler(`set typecheck ${process.execPath} canary.cjs`, ctx);
  assert.ok(existsSync(join(agent, 'project-profile/profiles')), 'initialization must remain enabled');
  return {cwd,branch,ctx,emit,loaded,notifications,canary:join(cwd,'CANARY')};
}
const prompt = () => ({prompt:'Inspect source only',systemPromptOptions:{contextFiles:[],sections:{}}});
const pause = () => new Promise(resolve => setTimeout(resolve, 400));

for (const entry of ['before_agent_start', 'tool_result', 'run_checks', 'agent_before_settle', 'turn_end', 'verify']) {
  test(`trusted parent ${entry} cannot execute checks before Implement`, async () => {
    const f = await profileFixture();
    if (entry === 'before_agent_start') await f.emit(entry, prompt());
    if (entry === 'tool_result') await f.emit(entry, {toolName:'read',input:{path:'source.ts'},content:[],isError:false});
    if (entry === 'run_checks') {
      const tool = f.loaded.extensions.flatMap(e => [...e.tools.values()]).find(t => t.definition.name === 'run_checks').definition;
      await tool.execute('canary',{},undefined,undefined,f.ctx);
    }
    if (entry === 'verify') {
      const command=f.loaded.extensions.flatMap(e=>[...e.commands.entries()]).find(([name])=>name==='verify')[1];
      await command.handler('',f.ctx);
    }
    if (entry === 'agent_before_settle' || entry === 'turn_end') {
      // A restored/external mutation notification must not authorize subprocesses.
      await f.emit('tool_result',{toolName:'write',input:{path:'source.ts'},content:[],isError:false});
      await f.emit(entry,{outcome:'completed',turnIndex:0,entries:[]});
    }
    await pause();
    assert.equal(existsSync(f.canary), false, 'project command ran with an empty plan branch');
    await f.emit('session_shutdown');
  });
}

test('approved parent and admitted child retain actual automatic project checks', async () => {
  for (const child of [false,true]) {
    const f = await profileFixture(child);
    if (!child) f.branch.push({type:'custom',customType:'plan-mode-state',data:{activeImplementation:{plan:'Run the harmless canary check'}}});
    await f.emit('before_agent_start', prompt());
    for (let i=0; i<30 && !existsSync(f.canary); i++) await new Promise(resolve=>setTimeout(resolve,100));
    assert.equal(existsSync(f.canary),true, 'automatic checks were removed rather than approval-gated');
    await f.emit('session_shutdown');
  }
});

test('actual pinned /plan start, complete and human implement admits checks; exit revokes approval', async () => {
  const f = await profileFixture(false,true);
  const command = f.loaded.extensions.flatMap(e=>[...e.commands.entries()]).find(([name])=>name==='plan')[1];
  const tool = name => f.loaded.extensions.flatMap(e=>[...e.tools.values()]).find(t=>t.definition.name===name).definition;
  await command.handler('start',f.ctx);
  assert.equal(f.branch.findLast(e=>e.customType==='plan-mode-state')?.data.enabled,true);
  await f.emit('before_agent_start',prompt());
  await tool('plan_mode_complete').execute('complete',{plan:'# Canary approval\n\nRun the existing harmless project typecheck; accept only when CANARY exists.'},undefined,undefined,f.ctx);
  await tool('run_checks').execute('unapproved-checks',{},undefined,undefined,f.ctx);
  await f.emit('tool_result',{toolName:'read',input:{path:'source.ts'},content:[],isError:false});
  await pause();
  assert.equal(existsSync(f.canary),false,'completed plan is not approval');
  await command.handler('implement',f.ctx);
  assert.ok(f.branch.findLast(e=>e.customType==='plan-mode-state')?.data.activeImplementation,'actual upstream human Implement did not persist approval: '+JSON.stringify({branch:f.branch,notifications:f.notifications}));
  await f.emit('before_agent_start',prompt());
  for(let i=0;i<30&&!existsSync(f.canary);i++) await new Promise(resolve=>setTimeout(resolve,100));
  assert.equal(existsSync(f.canary),true);
  const result=await tool('run_checks').execute('approved-checks',{},undefined,undefined,f.ctx);
  assert.equal(result.details.status,'green');
  await command.handler('exit',f.ctx);
  rmSync(f.canary);
  await f.emit('before_agent_start',prompt());
  await f.emit('tool_result',{toolName:'read',input:{path:'source.ts'},content:[],isError:false});
  await pause();
  assert.equal(existsSync(f.canary),false,'exiting implementation must revoke check admission');
  await f.emit('session_shutdown');
});

test('actual resource loader rejects ambient packages before any installer call in parent/child and reload', async () => {
  const calls = [];
  const originals = new Map();
  for (const name of ['installParsedSource','installNpm','installGit','refreshTemporaryGitSource','runNpmCommand']) {
    originals.set(name,DefaultPackageManager.prototype[name]);
    DefaultPackageManager.prototype[name] = async (...args) => {calls.push([name,args]); throw new Error('INTERCEPTED_INSTALLER');};
  }
  try {
    for (const child of [false,true]) {
      const dir = mkdtempSync(join(root,'packages-'));
      const cwd = join(dir,'project'), agent = join(dir,'agent');
      mkdirSync(cwd); mkdirSync(agent); mkdirSync(join(cwd,'.pi'));
      if(child) process.env.PI_DELEGATOR_CHILD='1'; else delete process.env.PI_DELEGATOR_CHILD;
      delete process.env.PI_OFFLINE; // Connected model networking cannot be the guard.
      const resources = new sdk.DefaultResourceLoader({cwd,agentDir:agent,noExtensions:true,noSkills:true,noPromptTemplates:true,
        additionalExtensionPaths:[nm + '/pi-ollama-cloud/index.ts']});
      resources.settingsManager.setProjectTrusted(true);
      await resources.reload();
      for (const target of [join(cwd,'.pi/settings.json'),join(agent,'settings.json')]) {
        writeFileSync(target, JSON.stringify({packages:['npm:pi-harness-canary-do-not-install@1.0.0','git:https://example.invalid/no-install'],extensions:['./evil.ts'],skills:['./evil']}));
        for(const instance of [resources,new sdk.DefaultResourceLoader({cwd,agentDir:agent,noExtensions:true,noSkills:true,noPromptTemplates:true})]) {
          instance.settingsManager.setProjectTrusted(true);
          let error;
          try {await instance.reload();} catch(e) {error=e;}
          assert.equal(calls.length,0,'resource loader reached installer BEFORE --no-extensions filtering');
          assert.match(String(error), /declarative|unapproved/i,'unapproved sources must fail closed');
        }
        writeFileSync(target,'{}');
      }
    }
  } finally {
    for(const [name,fn] of originals) DefaultPackageManager.prototype[name]=fn;
  }
});

test('mutable resource settings cannot substitute pinned extensions or skills on startup/reload', async () => {
  const dir = mkdtempSync(join(root,'resources-'));
  const cwd=join(dir,'project'), agent=join(dir,'agent');
  mkdirSync(cwd); mkdirSync(agent); mkdirSync(join(cwd,'.pi/extensions'),{recursive:true});
  writeFileSync(join(cwd,'.pi/extensions/evil.ts'), 'export default function(pi) { pi.registerCommand("evil", {description:"bad", handler(){}}); }');
  mkdirSync(join(agent,'evil-skill'));
  writeFileSync(join(agent,'evil-skill/SKILL.md'),'---\nname: evil\ndescription: Unapproved skill\n---\nBad');
  for (const target of [join(agent,'settings.json'),join(cwd,'.pi/settings.json')]) {
    writeFileSync(target,JSON.stringify({extensions:[join(cwd,'.pi/extensions/evil.ts')],skills:[join(agent,'evil-skill')]}));
  }
  for (const child of [false,true]) {
    if(child) process.env.PI_DELEGATOR_CHILD='1'; else delete process.env.PI_DELEGATOR_CHILD;
    const resources=new sdk.DefaultResourceLoader({cwd,agentDir:agent,additionalExtensionPaths:[nm+'/pi-ollama-cloud/index.ts']});
    resources.settingsManager.setProjectTrusted(true);
    for(let i=0;i<2;i++) {
      await resources.reload();
      assert.deepEqual(resources.getExtensions().errors,[]);
      assert.equal(resources.getExtensions().extensions.length,1,'ambient extension substituted declarative resources');
      assert.equal(resources.getSkills().skills.length,0,'ambient skill substituted declarative resources');
    }
  }
});

test('actual package manager refuses interactive install/update/remove and unapproved explicit sources without installer/network calls', async () => {
  const dir=mkdtempSync(join(root,'commands-'));
  const settings=sdk.SettingsManager.create(dir,dir);
  settings.setProjectTrusted(true);
  const pm=new DefaultPackageManager({cwd:dir,agentDir:dir,settingsManager:settings});
  const calls=[];
  for(const method of ['runNpmCommand','runCommand','refreshTemporaryGitSource','installParsedSource']) pm[method]=async()=>{calls.push(method);throw new Error('INTERCEPTED');};
  for(const operation of ['install','installAndPersist','update','remove','removeAndPersist']) {
    let error;
    try {await pm[operation]('npm:pi-canary-never-install@1.0.0');} catch(e) {error=e;}
    assert.equal(calls.length,0,`${operation} reached runtime installer`);
    assert.match(String(error),/declarative|unapproved/i);
  }
  for(const source of ['npm:pi-canary-never-install@1.0.0','git:https://example.invalid/no-download',dir]) {
    await assert.rejects(pm.resolveExtensionSources([source],{temporary:true}),/declarative|unapproved/i);
    assert.equal(calls.length,0);
  }
  assert.deepEqual(await pm.checkForAvailableUpdates(),[]);
  assert.throws(()=>new sdk.DefaultResourceLoader({cwd:dir,agentDir:dir,additionalSkillPaths:[dir]}),/declarative|unapproved/i);
});

test('published CLI/RPC entry points cannot bypass declarative package boundary via bundled copies', () => {
  const dir=mkdtempSync(join(root,'entrypoints-'));
  const agent=join(dir,'agent'); mkdirSync(agent);
  const canary=join(dir,'INSTALLER_CALLED');
  const installer=join(dir,'fake-installer.cjs');
  writeFileSync(installer,`require('node:fs').writeFileSync(${JSON.stringify(canary)},'installer reached'); process.exit(73);`);
  const settings={npmCommand:[process.execPath,installer]};
  const env={HOME:dir,PATH:'',TMPDIR:dir,PI_CODING_AGENT_DIR:agent,PI_SKIP_VERSION_CHECK:'1',PI_TELEMETRY:'0'};
  for(const entry of ['cli.js','bundle/cli.js','rpc-entry.js','bundle/rpc-entry.js']) {
    const rpc=entry.includes('rpc-entry');
    writeFileSync(join(agent,'settings.json'),JSON.stringify({...settings,...(rpc?{packages:['npm:pi-canary-do-not-install@1.0.0']}:{})}));
    const result=spawnSync(process.execPath,[nm+'/\u0040earendil-works/pi-coding-agent/dist/'+entry,...(rpc?['--approve','--no-extensions','--no-skills']:['install','npm:pi-canary-do-not-install@1.0.0'])],{cwd:dir,env,encoding:'utf8',input:'',timeout:10000});
    assert.equal(existsSync(canary),false,`${entry} reached the harmless intercepted installer`);
    assert.notEqual(result.status,0);
    assert.match(result.stderr+result.stdout,/declarative|unapproved/i,`${entry} did not use guarded API`);
  }
});

process.on('exit',()=>rmSync(root,{recursive:true,force:true}));
