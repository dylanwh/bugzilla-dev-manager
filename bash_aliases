BZ_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

alias bz="$BZ_ROOT/bz"
alias bzn="$BZ_ROOT/bzn"

function bznew {
    bz new "$@"
    BZ_DOCS=`perl -I"$BZ_ROOT" -MBz -e 'print Bz->config->htdocs_path'`
    cd "$BZ_DOCS/$1"
}

function cdb() {
    P=`bz path "$@"`
    if (( $? == 1 )) ; then
        T=`bz path --repo "$@"`
        if (( $? == 0 )); then
            P=$T
        fi
    fi
    cd $P
    bz summary
}

function cdr() {
    P=`bz path --repo "$@"`
    if (( $? == 1 )) ; then
        T=`bz path "$@"`
        if (( $? == 0 )); then
            P=$T
        fi
    fi
    cd $P
    bz summary
}
