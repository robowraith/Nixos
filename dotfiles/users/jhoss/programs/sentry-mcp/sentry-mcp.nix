{pkgs, ...}: {
  # Sentry MCP (stdio) for the self-hosted sentry.42he.com. Claude Code is registered against this
  # path (`claude mcp add sentry-42he -- ~/.local/bin/sentry-mcp-42he`). The read-write personal
  # token in ~/.config/sentry-mcp/token stays out of Nix (single RW token, ansible#1745).
  home.file.".local/bin/sentry-mcp-42he" = {
    force = true;
    source = pkgs.writeShellScript "sentry-mcp-42he" ''
      # Token comes from a 0600 file, never from arguments.
      set -euo pipefail
      f="''${XDG_CONFIG_HOME:-$HOME/.config}/sentry-mcp/token"
      [ -r "$f" ] || { echo "sentry-mcp-42he: missing token file $f" >&2; exit 1; }
      SENTRY_ACCESS_TOKEN="$(<"$f")"
      export SENTRY_ACCESS_TOKEN
      # Keep the embedded AI search off even when Claude Code's environment carries an LLM key.
      unset ANTHROPIC_API_KEY OPENAI_API_KEY OPENROUTER_API_KEY EMBEDDED_AGENT_PROVIDER
      # Pinned on purpose: this server has write access to Sentry, bump deliberately.
      export PATH="${pkgs.nodejs}/bin:$PATH"
      exec npx -y @sentry/mcp-server@0.42.0 --host=sentry.42he.com
    '';
  };
}
