# bash completion for anonbox
# Usage: source completions/anonbox.bash
# zsh: autoload -U +X bashcompinit && bashcompinit; source completions/anonbox.bash

_anonbox()
{
    local cur prev opts commands
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD - 1]}"
    commands="setup harden check doctor all status sync-iface rollback uninstall version help"
    opts="--bridges-file --no-bridges --iface --snapshot --allow-ssh --yes -y --no-kill-switch --quiet -q --silent --json --no-color --color --log-file --no-log --verbose -v --dry-run --help -h"

    if [[ ${COMP_CWORD} -eq 1 ]]; then
        # shellcheck disable=SC2207
        COMPREPLY=( $(compgen -W "${commands}" -- "${cur}") )
        return 0
    fi

    case "${prev}" in
        --bridges-file|--log-file)
            # shellcheck disable=SC2207
            COMPREPLY=( $(compgen -f -- "${cur}") )
            return 0
            ;;
        --iface)
            # shellcheck disable=SC2207
            COMPREPLY=( $(compgen -W "$(ls /sys/class/net 2>/dev/null)" -- "${cur}") )
            return 0
            ;;
        --snapshot)
            # shellcheck disable=SC2207
            COMPREPLY=( $(compgen -W "$(ls /var/backups/anonbox 2>/dev/null)" -- "${cur}") )
            return 0
            ;;
        --color)
            # shellcheck disable=SC2207
            COMPREPLY=( $(compgen -W "auto always never" -- "${cur}") )
            return 0
            ;;
    esac

    # shellcheck disable=SC2207
    COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
}

complete -F _anonbox anonbox
complete -F _anonbox ./anonbox
