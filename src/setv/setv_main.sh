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

export prog=`basename "${BASH_SOURCE[0]}" | cut -d. -f1 | cut -d_ -f1`

# Install / runtime directory
JEDI_SETV_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Default virtual environment directory; set if other than $HOME is desired
SETV_VIRTUAL_ENV_DIR=${SETV_VIRTUAL_ENV_DIR:-$HOME}

# Default python version to use
SETV_PY_PATH=$(which python3)
python_dot_version=$(python3 -c 'import sys;print(sys.version_info[0],".",sys.version_info[1],sep="")')

# Support python 3.x only, and >= 3.6
min_python_version=3.6
_version_check=`echo "$python_dot_version >= $min_python_version" | bc`
[ "$_version_check" -eq "1" ] || (echo "Must have a python version >= 3.5" && return)
_version=`echo "$python_dot_version == 3.9" | bc`

# Requirements file definitions; value is set in the setv module file, else ./requirements.txt is assumed
# DEFAULT_RQMTS=requirements.txt
# RQMT_FILE=${SETV_DEFAULT_RQMTS_FILE:-$DEFAULT_RQMTS}
RQMT_FILE=${SETV_DEFAULT_RQMTS_FILE}
_rqmt_file=""

# Initialize helper functions
source "${JEDI_SETV_DIR}/setv_fcn.sh"

# Current venv
_curr_venv=${VIRTUAL_ENV:-""}

#
# Main function
#
function setv() {
    #
    # Options:
    # H: create directory for venvs; defaults to $HOME
    # a: activate a venv
    # c: create a venv
    # p: populate a venv via pip and requirements file
    #       may specify '-r <requirements file>' to use requirements other than default
    # d: deactivate a venv
    # D: delete a venv
    # N: create / activate populate a venv
    # C: clone an existing venv
    # l: list available venvs
    # h: help / usage
    #

    local OPTIND opt
    local func=${FUNCNAME[0]}

    if [[ $# -eq 0 ]]; then
        _setv_help_
    fi

    while [[ "$#" -gt 0 ]]; do
        echo $@
        case "$1" in
            -h | --help)
                _setv_help_
                return
                ;;

            -l| --list)
                _setv_list
                return
                ;;

            -a | --activate)
                if ! _setv_checkArg $2 ; then
                    echo "$prog: activate: missing venv"
                    # shift
                    return
                else
                    venv=$2
                    _setv_activate $venv
                    shift 2
                fi
                ;;

            -d | --deactivate)
                if ! _setv_checkArg $2 ; then
                    echo "$prog: deactivate: missing venv"
                    # shift
                    return
                else
                    venv=$2
                    _setv_deactivate $venv
                    shift 2
                fi
                ;;

            -c | --create) 
                if ! _setv_checkArg $2 ; then
                    echo "$prog: create: missing venv"
                    # shift
                    return
                else
                    venv=$2
                    _setv_create $venv
                    shift 2
                fi
                ;;

            -D | --delete)
                if ! _setv_checkArg $2 ; then
                    echo "$prog: delete: missing venv"
                    # shift
                    return
                else
                    _setv_delete $2
                    shift 2
                fi
                ;;

            -p | --populate)
                if ! _setv_checkArg $2 ; then
                    echo "$prog: $func: populate: missing venv"
                    shift
                    return
                else
                    venv=$2
                    echo venv: $venv
                    shift
                    args=("$@")
                    echo args: $args
                    _setv_rqmts_file $@
                    echo rqmtsFile: $_rqmt_file
                    _setv_populate $venv $_rqmt_file
                    echo done: $args and  $@
                    shift
                    # [[ ${#args[@]} -ge 2 ]] && shift 2
                fi
                ;;

            -i | --install)
                echo $2 $3 $4
                echo $@
                if [ "$2" == "--package" ]; then
                    _rqmt_file=$3
                    venv=$4
                    shift 4
                else
                    venv=$2
                    shift 2
                fi

                # if ! _setv_checkArg $2 ; then
                #     echo "$prog: $install: missing venv"
                #     return
                # else
                    # venv=$2
                    _setv_create $venv
                    _setv_activate $venv

                    # shift 2
                    # echo rest of args: $@
                    # args=("$@")
                    # _setv_rqmts_file $@
                    # echo rqmts: $_rqmt_file
                    _setv_populate $venv $_rqmt_file
                    # [[ ${#args[@]} -ge 2 ]] && shift 2
                # fi
                ;;

           -u | --update)
                echo $2 $3 $4
                echo $@
                if [ "$2" == "--package" ]; then
                    _rqmt_file=$3
                    venv=$4
                    shift 4
                else
                    venv=$2
                    shift 2
                fi

                if ! _setv_venv_exists $venv ; then
                    echo checked for existence
                    return
                fi

                echo "if here, populate $venv with file $_rqmt_file"

                # if ! _setv_checkArg $2 ; then
                #     echo "$prog: $install: missing venv"
                #     return
                # else
                    # venv=$2
                    # _setv_create $venv
                    # _setv_activate $venv

                    # shift 2
                    # echo rest of args: $@
                    # args=("$@")
                    # _setv_rqmts_file $@
                    # echo rqmts: $_rqmt_file
                    _setv_populate $venv $_rqmt_file
                    # [[ ${#args[@]} -ge 2 ]] && shift 2
                # fi
                ;;

            -C | --clone)  
                if ! _setv_checkArg $2 ; then
                    echo "$prog: $func: missing venv"
                    return
                else
                    venv=$2
                    args=("$@")
                    clone="${args[2]}"
                    echo clone is $clone
                    _setv_clone $venv $clone
                    return
                fi
                ;; 
            *)
                echo "everything else: $@"
                return
            
            
            #    if [ -d ${SETV_VIRTUAL_ENV_PATH}/${1} ];
            #    then
            #        # if it exists, activate the virtual environment
            #        source ${SETV_VIRTUAL_ENV_PATH}/${1}/bin/activate
            #        cd ${SETV_VIRTUAL_ENV_PATH}/${1}
            #     #    _setv_populate
            #    else
            #        # no virtual environment with specified name
            #        echo "no virtual environment with the name: ${1}"
            #        _setv_help_
            #    fi
               ;;
        esac
    done

    return
}

# Calls bash-complete. The compgen command accepts most of the same
# options that complete does but it generates results rather than just
# storing the rules for future use.
complete  -F _setvcomplete_ setv
