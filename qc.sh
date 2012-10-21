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

function _c() {
    local cur prev opts bookmarks
    COMPREPLY=()
    bookmarks=""
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="-a --add -c --save_current -d --delete -l --list -L --list_all -h --help"

    case "${prev}" in
        -a|--add)
            bookmarks="$(c --bash_completion add)"
            ;;
        -l|--list|-L|--list_all|-c|--save_current|-h|--help)
            ;;
        -d|--delete)
            bookmarks="$(c --bash_completion bookmark)"
            ;;
        *)
            if [[ ${cur:0:1} == "-" ]]; then
                COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                return 0
            else
                local test="${COMP_WORDS[COMP_CWORD-1]}"
                if [ x"$test" == x"-a" ] || [ x"$test" == x"--add" ] ; then
                    bookmarks="$(c --bash_completion path)"
                else
                    bookmarks="$(c --bash_completion all)"
                fi
            fi
            ;;
    esac
    COMPREPLY=( $(compgen -W "${bookmarks}" -- ${cur}) )
}

complete -o nospace -F _c c
complete -o nospace -F _c qc
