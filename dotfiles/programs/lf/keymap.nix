{
  programs.lf.keybindings = {
    A = ":rename; cmd-end";
    D = "delete";
    E = "extract";
    gh = "cd ~";
    n = "push :touch<space>''<left>";
    N = "push :mkdir<space>''<left>";
    
 #    <c-f> $lf -remote "send $id select \"$(fzf)\""
 # J $lf -remote "send $id cd $(sed -e 's/\s*#.*//' -e '/^$/d' -e 's/^\S*\s*//' ${XDG_CONFIG_HOME:-$HOME/.config}/shell/bm-dirs | fzf)"
 # g top
 # <c-g> :fzf_search
 # N push :mkdir<space>""<left>
 # n push :touch<space>""<left>
 # <c-r> reload
 # <c-s> set hidden!
 # <enter> shell
 # x $$f
 # X !$f
 # o &mimeopen "$f"
 # O $mimeopen --ask "$f"
 # <c-z> z
 # <c-i> zi

 # A :rename; cmd-end # at the very end
 # r push A<c-u> # new rename
 # I :rename; cmd-home # at the very beginning
 # i :rename # before extension
 # a :rename; cmd-right # after extension
 # B bulkrename

 # <c-e> down
 # <c-y> up
 # V push :!nvim<space>

 # W $setsid -f $TERMINAL >/dev/null 2>&1

 # Y $printf "%s" "$fx" | xclip -selection clipboard
    
  };
}
