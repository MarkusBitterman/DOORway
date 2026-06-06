    # doorwayctl tab completion
    if command -v doorwayctl &>/dev/null; then
        compdef _doorwayctl doorwayctl
        eval "$(doorwayctl completion zsh)"
    fi
