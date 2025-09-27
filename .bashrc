#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export EDITOR=nano
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fastfetch='fastfetch -c /home/hugo/.config/fastfetch/detailed.jsonc'
PS1='[\u@\h \W]\$ '

# Created by `pipx` on 2025-07-24 16:29:14
export PATH="$PATH:/home/hugo/.local/bin"

source '/home/hugo/.bash_completions/comfy.sh'
[ -f /opt/miniforge/etc/profile.d/conda.sh ] && source /opt/miniforge/etc/profile.d/conda.sh
