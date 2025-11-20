{
  programs.lf.keybindings = {
    # Config editing
    C = "edit-config";
    
    # File selection and navigation
    "<c-f>" = "$lf -remote \"send $id select \\\"$(fzf)\\\"\"";
    J = "$lf -remote \"send $id cd $(sed -e 's/\\s*#.*//' -e '/^$/d' -e 's/^\\S*\\s*//' ''${XDG_CONFIG_HOME:-$HOME/.config}/shell/bm-dirs | fzf)\"";
    gh = "";
    g = "top";
    "<c-g>" = ":fzf_search";
    
    # File operations
    D = "delete";
    E = "extract";
    N = "push :mkdir<space>\"\"<left>";
    n = "push :touch<space>\"\"<left>";
    
    # Refresh and toggle
    "<c-r>" = "reload";
    "<c-s>" = "set hidden!";
    
    # Shell commands
    "<enter>" = "shell";
    x = "$$f";
    X = "!$f";
    o = "&mimeopen \"$f\"";
    O = "$mimeopen --ask \"$f\"";
    
    # Zoxide integration
    "<c-z>" = "z";
    "<c-i>" = "zi";
    
    # Renaming
    A = ":rename; cmd-end";  # at the very end
    r = "push A<c-u>";  # new rename
    I = ":rename; cmd-home";  # at the very beginning
    i = ":rename";  # before extension
    a = ":rename; cmd-right";  # after extension
    B = "bulkrename";
    
    # Navigation
    "<c-e>" = "down";
    "<c-y>" = "up";
    
    # Editor and terminal
    V = "push :!nvim<space>";
    W = "$setsid -f $TERMINAL >/dev/null 2>&1";
    
    # Clipboard
    Y = "$printf \"%s\" \"$fx\" | xclip -selection clipboard";
  };
}
