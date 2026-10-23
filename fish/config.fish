set -gx EDITOR nvim
set -gx VISUAL nvim

if status is-interactive
    set -g fish_greeting

    alias ls lsd
    alias tree 'lsd --tree'
    alias ip 'ip --color=auto'
    alias vi nvim
    alias ff fastfetch
end
