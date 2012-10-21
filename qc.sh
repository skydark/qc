#!/bin/bash

QC_BIN="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/qc"
QC_PYTHON=python

function c() {
    ret="$("$QC_PYTHON" "$QC_BIN" "$@")"
    case "$ret" in
        $'\n'*)
            echo "$ret" | sed '1d'
            ;;
        '')
            ;;
        *)
            # echo "DEBUG: $ret"
            builtin cd "$ret"
            ;;
    esac
}
