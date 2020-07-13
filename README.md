# setup zsh + tmux powerline

## Install ZSH + Oh My Zsh

Install fonts - https://github.com/ryanoasis/nerd-fonts
Note - For WSL, select Dejavu Mono sans for powerline

Install zsh + Oh My Zsh -
```
sudo apt install zsh
chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
```

Install tmux + powerline

```
sudo apt install -y powerline tmux
cat << EOF >> ~/.tmux.conf
set -g default-terminal "xterm-256color"
#set-option -g prefix M-w
set -sg escape-time 0
bind C send-keys "clear" c-m \; run-shell "sleep .3s" \; clear-history
bind h set -g status
bind-key j command-prompt -p "send pane to:"  "join-pane -t '%%'"
bind-key X setw synchronize-panes
bind + copy-mode
set-option -g lock-command vlock
bind L locks
bind m \
	setw -g mouse on \;\
	display "Mouse: ON"
bind M \
	setw -g mouse off \;\
	display "Mouse: OFF"
bind-key - select-layout even-vertical
bind-key \ select-layout even-horizontal 

bind r source-file ~/.tmux.conf \; display "Finished sourcing ~/.tmux.conf ."

# Set panel title
bind t command-prompt -p "Panel title:" "send-keys 'printf \"'\\033]2;%%\\033\\\\'\"' C-m"

# Send command to all panes in current session
# (https://scripter.co/command-to-every-pane-window-session-in-tmux/)
bind e command-prompt -p "Command:" \
         "run \"tmux list-panes -s -F '##{session_name}:##{window_index}.##{pane_index}' \
                | xargs -I PANE tmux send-keys -t PANE '%1' Enter\""
source /usr/share/powerline/bindings/tmux/powerline.conf
EOF
```

Reference - https://medium.com/@shivam1/make-your-terminal-beautiful-and-fast-with-zsh-shell-and-powerlevel10k-6484461c6efb
