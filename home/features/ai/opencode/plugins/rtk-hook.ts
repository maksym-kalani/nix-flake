/**
 * RTK (Rust Token Killer) hook plugin for opencode.
 *
 * Mirrors the Claude Code PreToolUse hook that rewrites shell commands
 * through `rtk` for 60-90% token savings on dev operation output.
 *
 * Original Claude Code hook: { matcher: "Bash", command: "rtk hook claude" }
 * Behaviour: `git status` → `rtk git status` (transparent proxying)
 */
import type { Plugin } from "@opencode-ai/plugin"

export default (async ({ $ }) => {
  return {
    "tool.execute.before": async (input, output) => {
      // Only intercept the bash tool
      if (input.tool !== "bash") return

      const command: string | undefined = output.args?.command
      if (!command) return

      // Skip if already an rtk command
      if (command.startsWith("rtk ")) return

      // Skip rtk meta commands that the user types directly
      const rtkMeta = ["rtk gain", "rtk discover", "rtk proxy", "rtk --version"]
      if (rtkMeta.some((m) => command.startsWith(m))) return

      // Prefix the command with rtk for token-optimized output
      output.args.command = `rtk ${command}`
    },
  }
}) satisfies Plugin
