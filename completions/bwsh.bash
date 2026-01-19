# ABOUTME: Bash completion script for bwsh (Bitwarden Secrets Manager wrapper)
# ABOUTME: Provides tab-completion for commands and secret names

_bwsh_completions() {
    local cur prev words cword
    _init_completion 2>/dev/null || {
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        words=("${COMP_WORDS[@]}")
        cword=$COMP_CWORD
    }

    # Commands
    local commands="get set list delete run env setup update version help"

    # Get list of secret names (cached for performance)
    _bwsh_secrets() {
        if command -v bwsh >/dev/null 2>&1; then
            bwsh list 2>/dev/null
        fi
    }

    # First argument: commands
    if [[ $cword -eq 1 ]]; then
        COMPREPLY=($(compgen -W "$commands" -- "$cur"))
        return
    fi

    # Second argument: depends on command
    case "${words[1]}" in
        get|delete)
            # Complete with secret names
            COMPREPLY=($(compgen -W "$(_bwsh_secrets)" -- "$cur"))
            ;;
        set)
            # First arg after set: secret name
            if [[ $cword -eq 2 ]]; then
                COMPREPLY=($(compgen -W "$(_bwsh_secrets)" -- "$cur"))
            fi
            # Second arg after set: value (no completion)
            ;;
        run)
            # Check for --project/-p flag value
            if [[ "$prev" == "--project" || "$prev" == "-p" ]]; then
                COMPREPLY=()  # No completion for project ID
            elif [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "--project -p" -- "$cur"))
            else
                # Complete with executables
                COMPREPLY=($(compgen -c -- "$cur"))
            fi
            ;;
        env)
            # Subcommands for env
            if [[ $cword -eq 2 ]]; then
                COMPREPLY=($(compgen -W "export import" -- "$cur"))
            elif [[ "${words[2]}" == "import" ]]; then
                # Check for --project/-p flag value
                if [[ "$prev" == "--project" || "$prev" == "-p" ]]; then
                    COMPREPLY=()  # No completion for project ID
                elif [[ "$cur" == -* ]]; then
                    COMPREPLY=($(compgen -W "--project -p --dry-run" -- "$cur"))
                else
                    # File completion for import
                    COMPREPLY=($(compgen -f -- "$cur"))
                fi
            fi
            ;;
        update)
            COMPREPLY=($(compgen -W "--check -c" -- "$cur"))
            ;;
        *)
            COMPREPLY=()
            ;;
    esac
}

# Also complete the shell functions when sourced
_bwgetkey_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    if command -v bwsh >/dev/null 2>&1; then
        COMPREPLY=($(compgen -W "$(bwsh list 2>/dev/null)" -- "$cur"))
    fi
}

_bwdelkey_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    if command -v bwsh >/dev/null 2>&1; then
        COMPREPLY=($(compgen -W "$(bwsh list 2>/dev/null)" -- "$cur"))
    fi
}

_bwkey_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local cword=$COMP_CWORD
    # Only complete first argument (key name)
    if [[ $cword -eq 1 ]] && command -v bwsh >/dev/null 2>&1; then
        COMPREPLY=($(compgen -W "$(bwsh list 2>/dev/null)" -- "$cur"))
    fi
}

_bwenv_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    local cword=$COMP_CWORD
    if [[ $cword -eq 1 ]]; then
        COMPREPLY=($(compgen -W "export import" -- "$cur"))
    elif [[ "${COMP_WORDS[1]}" == "import" ]]; then
        # Check for --project/-p flag value
        if [[ "$prev" == "--project" || "$prev" == "-p" ]]; then
            COMPREPLY=()  # No completion for project ID
        elif [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W "--project -p --dry-run" -- "$cur"))
        else
            COMPREPLY=($(compgen -f -- "$cur"))
        fi
    fi
}

_bwrun_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    # Check for --project/-p flag value
    if [[ "$prev" == "--project" || "$prev" == "-p" ]]; then
        COMPREPLY=()  # No completion for project ID
    elif [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "--project -p" -- "$cur"))
    else
        COMPREPLY=($(compgen -c -- "$cur"))
    fi
}

# Register completion functions
complete -F _bwsh_completions bwsh
complete -F _bwgetkey_completions bwgetkey
complete -F _bwdelkey_completions bwdelkey
complete -F _bwkey_completions bwkey
complete -F _bwenv_completions bwenv
complete -F _bwrun_completions bwrun
