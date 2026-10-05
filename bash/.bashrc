# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# Load numbered configuration modules; documentation is not sourced.
if [ -d "$HOME/.bashrc.d" ]; then
    for rc in "$HOME"/.bashrc.d/*.sh; do
        if [ -f "$rc" ] && [ -r "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc
