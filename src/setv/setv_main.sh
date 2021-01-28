#!/bin/bash
# © Copyright 2020 UCAR
# This software is licensed under the terms of the Apache Licence Version 2.0 which can be obtained at
# http://www.apache.org/licenses/LICENSE-2.0.
#
# Usage:
# From a .bashrc or any local rc script:
# 
# source <this file>
# see: setv_fcn.sh/_setup_help() for usage

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

# Requirements file definitions; value is set in the setv module file as: SETV_DEFAULT_RQMTS_FILE
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
    # see setv_fcn/_setv_help() for options

    local opt args cmd

    if [[ $# -eq 0 ]]; then
        _setv_help
    fi

    while [[ $# -gt 0 ]]; do
        args=$@
        opt=$1
        cmd=`echo $opt | cut -c 3-`
        case "$opt" in
            -h | --help)
                _setv_help
                return
                ;;

            -l | --list)
                _setv_list
                return
                ;;

            --venvdir)
                vdir="$2"
                _setv_vdir "$vdir"
                return
                ;;

            --activate | --deactivate | --create | --activate | --populate | --delete)
                    venv=$2
                    if [ "$cmd" == "populate" ]; then
                        _rqmt_file=$3
                        shift
                    fi

                    _setv_$cmd $venv $_rqmt_file
                    _rqmt_file=""
                    shift 3
                    return
                    ;;

            --install | --update)
                case $# in
                    2) 
                        # rqmts file not specified; install a basic venv
                        venv=$2
                        shift 2
                        ;;

                    4)
                        # rqmts file specified; install that in the venv
                        _pArg=$2
                        if [[ "$_pArg" == "--package" ]]; then
                            _rqmt_file=$3
                            venv=$4
                            shift 4
                        else
                            _setv_help
                            return
                        fi
                        ;;

                    *) 
                        echo "$prog: invalid usage $prog $args"
                        return
                        ;;
                esac

                case $cmd in
                    install)
                        _setv_venv_exists $venv
                        ret=$?
                        if [ $ret -eq 0 ]; then
                            echo "$prog: venv '$venv' already exists"
                            return
                        else
                            echo "$prog: installing venv '$venv'"
                            _setv_create $venv && _setv_activate $venv && _setv_populate $venv $_rqmt_file
                            return
                        fi
                        ;;

                    update)
                        if [ -z $_rqmt_file ]; then
                            echo "$prog: must specify a package file from which to update venv '$venv'"
                            return
                        else
                            echo "$prog: updating venv '$venv'"
                            # venv exists but may not be active; if the venv to update isn't active,
                            # current venv will be deactivated and venv to be updated becomes active
                            _setv_activate $venv && _setv_populate $venv $_rqmt_file
                        fi

                        return
                        ;;
                esac
                ;;

            --clone)
                case $# in
                    3)
                        venv=$2
                        clone=$3
                        _setv_clone $venv $clone
                        shift 4
                        return
                        ;;

                    *)
                        echo -e "$prog: invalid usage $prog $args\n"
                        return
                        ;;
                esac
                ;;

            --switch)
                case $# in
                    2)
                        venv=$2
                        _setv_switch $venv
                        shift 3
                        return
                        ;;

                    *)
                        echo -e "$prog: invalid usage $prog $args\n"
                        return
                        ;;
                esac
                ;;

            *)
                echo -e "$prog $@ : unknown or invalid command\n"
                return
               ;;
        esac
    done

    return
}

# Calls bash-complete. The compgen command accepts most of the same
# options that complete does but it generates results rather than just
# storing the rules for future use.
complete  -F _setvcomplete_ setv
