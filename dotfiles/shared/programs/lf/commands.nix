{
  programs.lf.commands = {
    open = ''
      ''${{
        case $(file --mime-type "$(readlink -f $f)" -b) in
        application/vnd.openxmlformats-officedocument.spreadsheetml.sheet) localc $fx ;;
        image/vnd.djvu|application/pdf|application/octet-stream|application/postscript) setsid -f zathura $fx >/dev/null 2>&1 ;;
            text/*|application/json|inode/x-empty|application/x-subrip) $EDITOR $fx;;
        image/x-xcf) setsid -f gimp $f >/dev/null 2>&1 ;;
        image/svg+xml) display -- $f ;;
        image/*) rotdir $f | grep -i "\.\(png\|jpg\|jpeg\|gif\|webp\|avif\|tif\|ico\)\(_large\)*$" |
            setsid -f nsxiv -aio 2>/dev/null | while read -r file; do
                [ -z "$file" ] && continue
                lf -remote "send select \"$file\""
                lf -remote "send toggle"
            done &
            ;;
        audio/*|video/x-ms-asf) mpv --audio-display=no $f ;;
        video/*) setsid -f mpv $f -quiet >/dev/null 2>&1 ;;
        application/pdf|application/vnd.djvu|application/epub*) setsid -f mupdf $fx >/dev/null 2>&1 ;;
        application/pgp-encrypted) $EDITOR $fx ;;
        application/vnd.openxmlformats-officedocument.wordprocessingml.document|application/vnd.oasis.opendocument.text|application/vnd.openxmlformats-officedocument.spreadsheetml.sheet|application/octet-stream|application/vnd.oasis.opendocument.spreadsheet|application/vnd.oasis.opendocument.spreadsheet-template|application/vnd.openxmlformats-officedocument.presentationml.presentation|application/vnd.oasis.opendocument.presentation-template|application/vnd.oasis.opendocument.presentation|application/vnd.ms-powerpoint|application/vnd.oasis.opendocument.graphics|application/vnd.oasis.opendocument.graphics-template|application/vnd.oasis.opendocument.formula|application/vnd.oasis.opendocument.database) setsid -f libreoffice $fx >/dev/null 2>&1 ;;
            *) for f in $fx; do setsid -f $OPENER $f >/dev/null 2>&1; done;;
        esac
    }}'';
    
    mkdir = ''
      ''${{
        mkdir -p "$@"
      }}'';
    
    touch = ''
      ''${{
        touch "$@"
      }}'';
    
    extract = ''
      ''${{
        clear; tput cup $(($(tput lines)/3)); tput bold
        set -f
        printf "%s\n\t" "$fx"
        printf "extract?[y/N]"
        read ans
        [ $ans = "y" ] && {
          case $fx in
            *.tar.bz2)   tar xjf $fx     ;;
            *.tar.gz)    tar xzf $fx     ;;
            *.bz2)       bunzip2 $fx     ;;
            *.rar)       unrar e $fx     ;;
            *.gz)        gunzip $fx      ;;
            *.tar)       tar xf $fx      ;;
            *.tbz2)      tar xjf $fx     ;;
            *.tgz)       tar xzf $fx     ;;
            *.zip)       unzip $fx       ;;
            *.Z)         uncompress $fx  ;;
            *.7z)        7z x $fx        ;;
            *.tar.xz)    tar xf $fx      ;;
          esac
        }
    }}'';
    
    delete = ''
      ''${{
        clear; tput cup $(($(tput lines)/3)); tput bold
        set -f
        printf "%s\n\t" "$fx"
        printf "delete?[y/N]"
        read ans
        [ $ans = "y" ] && rm -rf -- $fx
    }}'';
    
    moveto = ''
      ''${{
        clear; tput cup $(($(tput lines)/3)); tput bold
        set -f
        clear; echo "Move to where?"
        dest="$(sed -e 's/\s*#.*//' -e '/^$/d' -e 's/^\S*\s*//' ''${XDG_CONFIG_HOME:-$HOME/.config}/shell/bm-dirs | fzf | sed 's|~|$HOME|')" &&
        for x in $fx; do
          eval mv -iv \"$x\" \"$dest\"
        done &&
        notify-send "🚚 File(s) moved." "File(s) moved to $dest."
    }}'';
    
    copyto = ''
      ''${{
        clear; tput cup $(($(tput lines)/3)); tput bold
        set -f
        clear; echo "Copy to where?"
        dest="$(sed -e 's/\s*#.*//' -e '/^$/d' -e 's/^\S*\s*//' ''${XDG_CONFIG_HOME:-$HOME/.config}/shell/bm-dirs | fzf | sed 's|~|$HOME|')" &&
        for x in $fx; do
          eval cp -ivr \"$x\" \"$dest\"
        done &&
        notify-send "📋 File(s) copied." "File(s) copies to $dest."
    }}'';
    
    bulkrename = ''
      ''${{
        tmpfile_old="$(mktemp)"
        tmpfile_new="$(mktemp)"

        [ -n "$fs" ] && fs=$(basename -a $fs) || fs=$(ls)

        echo "$fs" > "$tmpfile_old"
        echo "$fs" > "$tmpfile_new"
        $EDITOR "$tmpfile_new"

        [ "$(wc -l < "$tmpfile_old")" -eq "$(wc -l < "$tmpfile_new")" ] || { rm -f "$tmpfile_old" "$tmpfile_new"; exit 1; }

        paste "$tmpfile_old" "$tmpfile_new" | while IFS="$(printf '\t')" read -r src dst
        do
            [ "$src" = "$dst" ] || [ -e "$dst" ] || mv -- "$src" "$dst"
        done

        rm -f "$tmpfile_old" "$tmpfile_new"
        lf -remote "send $id unselect"
    }}'';
    
    edit-config = ''
      ''${{
        $EDITOR ~/.config/lf/lfrc
        lf -remote "send $id source ~/.config/lf/lfrc"
    }}'';
    
    z = ''%{{
      result="$(zoxide query --exclude "$PWD" "$@" | sed 's/\\/\\\\/g;s/"/\\"/g')"
      lf -remote "send $id cd \"$result\""
    }}'';
    
    zi = ''
      ''${{
        result="$(zoxide query -i | sed 's/\\/\\\\/g;s/"/\\"/g')"
        lf -remote "send $id cd \"$result\""
    }}'';
  };
}

# TODO:
# cmd extract ${{
# 	clear; tput cup $(($(tput lines)/3)); tput bold
# 	set -f
# 	printf "%s\n\t" "$fx"
# 	printf "extract?[y/N]"
# 	read ans
# 	[ $ans = "y" ] && {
# 		case $fx in
# 			*.tar.bz2)   tar xjf $fx     ;;
# 			*.tar.gz)    tar xzf $fx     ;;
# 			*.bz2)       bunzip2 $fx     ;;
# 			*.rar)       unrar e $fx     ;;
# 			*.gz)        gunzip $fx      ;;
# 			*.tar)       tar xf $fx      ;;
# 			*.tbz2)      tar xjf $fx     ;;
# 			*.tgz)       tar xzf $fx     ;;
# 			*.zip)       unzip $fx       ;;
# 			*.Z)         uncompress $fx  ;;
# 			*.7z)        7z x $fx        ;;
# 			*.tar.xz)    tar xf $fx      ;;
# 		esac
# 	}
# }}

# cmd delete ${{
# 	clear; tput cup $(($(tput lines)/3)); tput bold
# 	set -f
# 	printf "%s\n\t" "$fx"
# 	printf "delete?[y/N]"
# 	read ans
# 	[ $ans = "y" ] && rm -rf -- $fx
# }}

# cmd moveto ${{
# 	clear; tput cup $(($(tput lines)/3)); tput bold
# 	set -f
# 	clear; echo "Move to where?"
# 	dest="$(sed -e 's/\s*#.*//' -e '/^$/d' -e 's/^\S*\s*//' ${XDG_CONFIG_HOME:-$HOME/.config}/shell/bm-dirs | fzf | sed 's|~|$HOME|')" &&
# 	for x in $fx; do
# 		eval mv -iv \"$x\" \"$dest\"
# 	done &&
# 	notify-send "🚚 File(s) moved." "File(s) moved to $dest."
# }}

# cmd copyto ${{
# 	clear; tput cup $(($(tput lines)/3)); tput bold
# 	set -f
# 	clear; echo "Copy to where?"
# 	dest="$(sed -e 's/\s*#.*//' -e '/^$/d' -e 's/^\S*\s*//' ${XDG_CONFIG_HOME:-$HOME/.config}/shell/bm-dirs | fzf | sed 's|~|$HOME|')" &&
# 	for x in $fx; do
# 		eval cp -ivr \"$x\" \"$dest\"
# 	done &&
# 	notify-send "📋 File(s) copied." "File(s) copies to $dest."
# }}

# cmd bulkrename ${{
#     tmpfile_old="$(mktemp)"
#     tmpfile_new="$(mktemp)"

#     [ -n "$fs" ] && fs=$(basename -a $fs) || fs=$(ls)

#     echo "$fs" > "$tmpfile_old"
#     echo "$fs" > "$tmpfile_new"
#     $EDITOR "$tmpfile_new"

#     [ "$(wc -l < "$tmpfile_old")" -eq "$(wc -l < "$tmpfile_new")" ] || { rm -f "$tmpfile_old" "$tmpfile_new"; exit 1; }

#     paste "$tmpfile_old" "$tmpfile_new" | while IFS="$(printf '\t')" read -r src dst
#     do
#         [ "$src" = "$dst" ] || [ -e "$dst" ] || mv -- "$src" "$dst"
#     done

#     rm -f "$tmpfile_old" "$tmpfile_new"
#     lf -remote "send $id unselect"
# }}

# cmd edit-config ${{
#     $EDITOR ~/.config/lf/lfrc
#     lf -remote "send $id source ~/.config/lf/lfrc"
# }}

# # bash/any POSIX shell

# cmd z %{{
#     result="$(zoxide query --exclude "$PWD" "$@" | sed 's/\\/\\\\/g;s/"/\\"/g')"
#     lf -remote "send $id cd \"$result\""
# }}

# cmd zi ${{
#     result="$(zoxide query -i | sed 's/\\/\\\\/g;s/"/\\"/g')"
#     lf -remote "send $id cd \"$result\""
# }}

# cmd on-cd &{{
#     zoxide add "$PWD"
# }}

# cmd fzf_search ${{
#     cmd="rg --column --line-number --no-heading --color=always --smart-case"
#     fzf --ansi --disabled --layout=reverse --header="Search in files" --delimiter=: \
#         --bind="start:reload([ -n {q} ] && $cmd -- {q} || true)" \
#         --bind="change:reload([ -n {q} ] && $cmd -- {q} || true)" \
#         --bind='enter:become(lf -remote "send $id select \"$(printf "%s" {1} | sed '\''s/\\/\\\\/g;s/"/\\"/g'\'')\"")' \
#         --preview='cat -- {1}' # Use your favorite previewer here (bat, source-highlight, etc.), for example:
#         #--preview-window='+{2}-/2' \
#         #--preview='bat --color=always --highlight-line={2} -- {1}'
#         # Alternatively you can even use the same previewer you've configured for lf
#         #--preview='~/.config/lf/cleaner; ~/.config/lf/previewer {1} "$FZF_PREVIEW_COLUMNS" "$FZF_PREVIEW_LINES" "$FZF_PREVIEW_LEFT" "$FZF_PREVIEW_TOP"'
# }}
