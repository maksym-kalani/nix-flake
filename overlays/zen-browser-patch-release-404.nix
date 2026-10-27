# Temporary pin for https://github.com/youwen5/zen-browser-flake/issues/22; drop once upstream releases download again.
{ inputs }:
_final: prev:
let
  system = prev.stdenv.hostPlatform.system;
  upstream = inputs.zen-browser.packages.${system};
  sources = {
    x86_64-linux = {
      url = "https://github.com/zen-browser/desktop/releases/download/1.23.2b/zen.linux-x86_64.tar.xz";
      hash = "sha256-Xmf0+ggbG0NyQ8RkRJ6hvSo7Fbb5Mkh6iqDCWqhRRgA=";
    };
    aarch64-linux = {
      url = "https://github.com/zen-browser/desktop/releases/download/1.23.2b/zen.linux-aarch64.tar.xz";
      hash = "sha256-lpcfCZwK3q5qLttOEoWW0HBt+XSsJ5tezeKqk7B2Idg=";
    };
  };
  unwrapped = upstream.zen-browser-unwrapped.override (sources.${system} // {
    version = "1.23.2b";
    firefoxVersion = "157.0.1";
  });
in
{
  zen-browser = upstream.default.override { zen-browser-unwrapped = unwrapped; };
}
