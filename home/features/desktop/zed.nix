{ ... }:
{
  programs.zed-editor = {
    enable = true;
    userSettings = {
      agent_servers.claude-acp.type = "registry";
    };
  };
}
