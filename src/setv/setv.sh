#!/bin/bash
# © Copyright 2020 UCAR
# This software is licensed under the terms of the Apache Licence Version 2.0 which can be obtained at
# http://www.apache.org/licenses/LICENSE-2.0.
#
# Usage:
# From a .bashrc or any local rc script:
# 
# source <this file>
# see: setv_fcn.sh/_setup_help_() for usage

# Global failure code
setv_fail=255

set +e

# Install / runtime directory
JEDI_SETV_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Default python version to use
SETV_PY_PATH=$(which python3)
python_dot_version=$($SETV_PY_PATH -c 'import sys;print(sys.version_info[0],".",sys.version_info[1],sep="")')

# Support python 3.x only, and >= 3.5
min_python_version=3.5
_version_check=`echo "$python_dot_version >= $min_python_version" | bc`
[ "$_version_check" -eq "1" ] || (echo "Must have a python version >= 3.5" && return)
_version=`echo "$python_dot_version == 3.9" | bc`

# Requirements file definitions; default value is set in the setv module file
DEFAULT_RQMTS=requirements.txt
RQMT_FILE=$SETV_DEFAULT_RQMTS_FILE
_rqmt_file=""

# Keep initial prompt; used to reset when a venv is deactivated or deleted
old_PS1=$PS1

# Initialize helper functions
source "${JEDI_SETV_DIR}/setv_fcn.sh"

function setv() {
    #
    # Options:
    # a: activate a venv
    # c: create a venv
    # p: populate a venv via pip and requirements file
    #       may specify '-r <requirements file>' to use requirements other than default
    # d: deactivate a venv
    # D: delete a venv
    # N: create / activate populate a venv
    # l: list available venvs
    # h: help / usage
    #

    local OPTIND opt
    local func=${FUNCNAME[0]}

    if [[ $# -eq 0 ]]; then
        _setv_help_
    fi

    while getopts "a:c:p:d:D:N:lh" opt; do
        case $opt in
            a)  if ! _setv_checkArg $OPTARG ; then
                    echo "$func: activate: missing venv NAME"
                    return
                else
                    _setv_activate $OPTARG
                fi
                ;;

            c)  if ! _setv_checkArg $OPTARG ; then
                    echo "$func: create: missing venv NAME"
                    return
                else
                    _setv_create $OPTARG
                fi
                ;;

            p)  if ! _setv_checkArg $OPTARG ; then
                    echo "$func: populate: missing venv NAME"
                    return
                else
                    args=("$@")
                    _setv_rqmts_file $@

                    _setv_populate $OPTARG $_rqmt_file
                    [[ ${#args[@]} -ge 2 ]] && shift 2
                fi
                ;;

            d)  if ! _setv_checkArg $OPTARG ; then
                    echo "$func: deactivate: missing venv NAME"
                    return
                else
                    _setv_deactivate $OPTARG
                fi
                ;;

            D) if ! _setv_checkArg $OPTARG ; then
                    echo "$func: Delete: missing venv NAME"
                    return
                else
                    _setv_delete $OPTARG
                fi
                ;;

            l)  _setv_list
                ;;

            h) _setv_help_
                ;;

            N)  if ! _setv_checkArg $OPTARG ; then
                    echo "$func: New: missing venv NAME"
                    return
                else
                    _setv_create $OPTARG
                    _setv_activate $OPTARG

                    args=("$@")
                    _setv_rqmts_file $@
                    _setv_populate $OPTARG $_rqmt_file
                    [[ ${#args[@]} -ge 2 ]] && shift 2
                fi
                ;;

            \?) _setv_help_
                ;;

            -*) _setv_help_
                ;;
        esac
    done

    shift $((OPTIND -1))
    return
}

# Calls bash-complete. The compgen command accepts most of the same
# options that complete does but it generates results rather than just
# storing the rules for future use.
complete  -F _setvcomplete_ setv

# setv $@
