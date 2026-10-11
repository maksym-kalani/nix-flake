{
  bash,
  buildNpmPackage,
  nodejs_24,
  makeWrapper,
  lib,
}:
buildNpmPackage {
  pname = "belial-pi-runtime";
  version = "1.1.0";
  src = ./npm;
  nodejs = nodejs_24;
  npmDepsHash = "sha256-08XG9jm1yrdfowdF9nBMkhuJ8vmzUkFIIiXmcYy/ryI=";
  npmFlags = [
    "--legacy-peer-deps"
    "--ignore-scripts"
  ];
  npmRebuildFlags = [ "--ignore-scripts" ];
  dontNpmBuild = true;
  dontNpmPrune = true;
  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/pi $out/bin
    cp -r node_modules package.json package-lock.json $out/lib/pi/
    ${import ./pi-delegator-patch-nix-launch-shell.nix { inherit bash; }}
    ${import ./pi-ollama-cloud-patch-remaining-status.nix}
    ${import ./pi-coding-agent-patch-declarative-resources.nix}
    makeWrapper ${nodejs_24}/bin/node $out/bin/pi-internal \
      --add-flags "$out/lib/pi/node_modules/@earendil-works/pi-coding-agent/dist/cli.js" \
      --set PI_SKIP_VERSION_CHECK 1 --set PI_TELEMETRY 0
    runHook postInstall
  '';
  meta = {
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
