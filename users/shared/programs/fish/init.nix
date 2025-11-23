{
  programs.fish.shellInit = ''
    # start SSH-Agent if it is not running
    if not pgrep -f ssh-agent >/dev/null
      eval (ssh-agent -c)
      set -Ux SSH_AUTH_SOCK $SSH_AUTH_SOCK
      set -Ux SSH_AGENT_PID $SSH_AGENT_PID
    end
    '';
}
