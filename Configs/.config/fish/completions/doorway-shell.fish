# Fish completion for doorway-shell

function __doorway_shell_get_commands
    echo "--help
help
-h
-r
reload
wallbash
--version
version
-v
--release-notes
release-notes
--list-script
--list-script-path
--completions"
    
    # Get doorway scripts
    if command -v doorway-shell >/dev/null 2>&1
        doorway-shell --list-script 2>/dev/null | sed 's/\.[^.]*$//'
    end
end

function __doorway_shell_get_wallbash_scripts
    # Just --help for now
    echo "--help"
end

# Main completions
complete -c doorway-shell -f

# First argument completions
complete -c doorway-shell -n "not __fish_seen_subcommand_from (__doorway_shell_get_commands)" -a "(__doorway_shell_get_commands)" -d "Hyde shell commands"

# Wallbash subcommand completions
complete -c doorway-shell -n "__fish_seen_subcommand_from wallbash" -a "(__doorway_shell_get_wallbash_scripts)" -d "Wallbash scripts"

# Completions subcommand
complete -c doorway-shell -n "__fish_seen_subcommand_from --completions" -a "bash zsh fish" -d "Shell completion types"

# Option descriptions
complete -c doorway-shell -s h -l help -d "Display help message"
complete -c doorway-shell -s r -d "Reload HyDE"
complete -c doorway-shell -s v -l version -d "Show version information"
complete -c doorway-shell -l release-notes -d "Show release notes"
complete -c doorway-shell -l list-script -d "List available scripts"
complete -c doorway-shell -l list-script-path -d "List scripts with full paths"
complete -c doorway-shell -l completions -d "Generate shell completions"
