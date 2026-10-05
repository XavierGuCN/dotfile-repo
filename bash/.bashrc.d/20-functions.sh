[[ $- == *i* ]] || return 0

# Keep normal cd arguments (including cd, cd -, and cd -P).
unalias cd 2>/dev/null || :
function cd {
    builtin cd "$@" || return "$?"
    command ls --color=auto
    # A listing failure must not change cd's successful exit status.
    return 0
}

# Create a directory (including parents), then enter and list it.
function mkcd {
    if [[ $# != 1 ]]; then
        printf 'Usage: mkcd DIRECTORY\n' >&2
        return 2
    fi
    command mkdir -p -- "$1" && cd -- "$1"
}
