import { realpathSync } from 'node:fs';

const refused = () => { throw new Error('Pi harness: declarative resources only; unapproved runtime package/resource operation'); };

export function assertPinnedResource(source) {
  if (typeof source !== 'string' || !source.startsWith('/nix/store/')) refused();
  // Check the target as well as the spelling: mutable symlink targets are not pins.
  let canonical;
  try { canonical = realpathSync(source); } catch { refused(); }
  if (!canonical.startsWith('/nix/store/')) refused();
}

export function assertLoaderResources(loader) {
  for (const key of ['additionalExtensionPaths', 'additionalSkillPaths', 'additionalPromptTemplatePaths', 'additionalThemePaths']) {
    for (const source of loader[key] ?? []) assertPinnedResource(source);
  }
}

export function enforceDeclarativePackages(PackageManager) {
  const prototype = PackageManager.prototype;
  // This dedicated Nix runtime never reads ambient resource lists or discovers
  // mutable resources. Other SettingsManager keys (models/login/UI) are untouched.
  prototype.resolve = async function () {
    for (const settings of [this.settingsManager.getGlobalSettings(), this.settingsManager.getProjectSettings()]) {
      if ((settings.packages ?? []).length) refused();
    }
    const accumulator = this.createAccumulator();
    for (const name of this.builtinExtensions) {
      this.addResource(accumulator.extensions, `builtin:${name}`, {source:'builtin',scope:'user',origin:'top-level'}, true);
    }
    return this.toResolvedPaths(accumulator);
  };
  const resolveSources = prototype.resolvePackageSources;
  prototype.resolvePackageSources = async function (sources, ...args) {
    // Validate the entire batch BEFORE parsing, version queries, installMissing,
    // or temporary Git refresh. Only explicit immutable filesystem resources.
    for (const {pkg, scope} of sources) {
      if (scope !== 'temporary' || typeof pkg !== 'string') refused();
      assertPinnedResource(pkg);
    }
    return resolveSources.call(this, sources, ...args);
  };
  prototype.checkForAvailableUpdates = async () => [];
  for (const method of ['install', 'installAndPersist', 'remove', 'removeAndPersist', 'update',
    'updateConfiguredSources', 'updateNpmBatch', 'installNpmBatch', 'installParsedSource',
    'installNpm', 'uninstallNpm', 'installGit', 'updateGit', 'refreshTemporaryGitSource', 'removeGit',
    'runNpmCommand', 'runNpmCommandSync', 'runGitRemoteCommand']) {
    prototype[method] = refused;
  }
}
