#!/usr/bin/env zsh

#! ██████╗░░█████╗░  ███╗░░██╗░█████╗░████████╗  ███████╗██████╗░██╗████████╗
#! ██╔══██╗██╔══██╗  ████╗░██║██╔══██╗╚══██╔══╝  ██╔════╝██╔══██╗██║╚══██╔══╝
#! ██║░░██║██║░░██║  ██╔██╗██║██║░░██║░░░██║░░░  █████╗░░██║░░██║██║░░░██║░░░
#! ██║░░██║██║░░██║  ██║╚████║██║░░██║░░░██║░░░  ██╔══╝░░██║░░██║██║░░░██║░░░
#! ██████╔╝╚█████╔╝  ██║░╚███║╚█████╔╝░░░██║░░░  ███████╗██████╔╝██║░░░██║░░░
#! ╚═════╝░░╚════╝░  ╚═╝░░╚══╝░╚════╝░░░░╚═╝░░░  ╚══════╝╚═════╝░╚═╝░░░╚═╝░░░


# Sources vital global environment variables and configurations // Users are encouraged to use ./user.zsh for customization
# shellcheck disable=SC1091
if ! . "$ZDOTDIR/conf.d/doorway/env.zsh"; then
    echo "Error: Could not source $ZDOTDIR/conf.d/doorway/env.zsh"
    return 1
fi

if [[ $- == *i* ]] && [ -f "$ZDOTDIR/conf.d/doorway/terminal.zsh" ]; then
    . "$ZDOTDIR/conf.d/doorway/terminal.zsh" || echo "Error: Could not source $ZDOTDIR/conf.d/doorway/terminal.zsh"
fi
