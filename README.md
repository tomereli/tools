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
```

Clone this repository and update `~/.tmux.conf` and `~/.zshrc`

```
cd
git clone https://github.com/tomereli/tools
cp tools/.tmux.conf ~/
cp tools/.zshrc ~/
cp tools/.pk10.zsh ~/
```

Update user name in ~/.zshrc

Open a new shell or `source ~/.zshrc` and you're done

Reference - https://medium.com/@shivam1/make-your-terminal-beautiful-and-fast-with-zsh-shell-and-powerlevel10k-6484461c6efb
