### Synopsys License File
# Synopsys License Environment
export Synopsys_DIR=/opt/synopsys
export SNPSLMD_LICENSE_FILE=27080@xavier-p16-fedora
export LM_LICENSE_FILE=$Synopsys_DIR/synopsys.lic

alias lmg_start='lmgrd -c /opt/synopsys/synopsys.lic -l /opt/synopsys/lmg_start_lic.log'
alias lmg_stop='lmdown -q -c 27080@xavier-p16-fedora'
alias lmg_check='lmutil lmstat -a -c 27080@xavier-p16-fedora'

### SCL
export SCL_VERSION=2025.03
export SCL_HOME=$Synopsys_DIR/scl/$SCL_VERSION/linux64
export PATH=$PATH:$SCL_HOME/linux64/bin

### VCS
export VCS_HOME=$Synopsys_DIR/vcs/Y-2026.03-SP2
export PATH=$VCS_HOME/bin:$PATH

### Verdi
export VERDI_HOME=$Synopsys_DIR/verdi/Y-2026.03-SP2
export PATH=$VERDI_HOME/bin:$PATH

### DC
export DC_HOME=$Synopsys_DIR/syn/Y-2026.03-SP2
export PATH=$DC_HOME/bin:$PATH

# GUI compatibility for Fedora KDE/Wayland (validated 2026-10-04).
# Keep these overrides local to Synopsys processes.
design_vision() {
    QT_QPA_PLATFORM=xcb QT_XCB_GL_INTEGRATION=none command "$DC_HOME/bin/design_vision" "$@"
}

dc_shell() {
    QT_QPA_PLATFORM=xcb QT_XCB_GL_INTEGRATION=none command "$DC_HOME/bin/dc_shell" "$@"
}

verdi() {
    QT_QPA_PLATFORM=xcb QT_XCB_GL_INTEGRATION=none \
        LD_PRELOAD="/lib64/libsystemd.so.0${LD_PRELOAD:+:$LD_PRELOAD}" \
        command "$VERDI_HOME/bin/verdi" "$@"
}
