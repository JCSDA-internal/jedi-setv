#!/bin/bash
# © Copyright 2020 UCAR
# This software is licensed under the terms of the Apache Licence Version 2.0 which can be obtained at
# http://www.apache.org/licenses/LICENSE-2.0.

# functions for managing python virtual environments

function _setvcomplete_()
{
    # Bash-autocompletion; ensures Tab-auto-completions work for virtual environment names

    # Available commands (currently: only 'setv')
    local cmd="${1##*/}"

    # Words to be completed
    local word=${COMP_WORDS[COMP_CWORD]}

    # Filter pattern; include only words in variable '$names'
    local xpat='${word}'

    # virtual environment names
    local names=$(ls -l "${SETV_VIRTUAL_ENV_DIR}" | egrep '^d' | awk -F " " '{print $NF}') 

    # bash built-in 'compgen' generates the results
    COMPREPLY=($(compgen -W "$names" -X "$xpat" -- "$word"))
}

function _setv_help_() {
    echo
    echo "Usage: setv [options] [NAME]"
    echo Optional arguments:
    echo -e "-h       help (show this information)"
    echo -e "-l       list available virtual environments\n"
    echo -e "-H <dir> specify virtual environment location"
    echo -e "-c NAME  create new virtual environment 'NAME'"
    echo -e "-a NAME  activate virtual enrvironment 'NAME'"
    echo -e "-p NAME  [ -r <requirements file>]  populate virtual environment 'NAME'"
    echo -e "-N NAME  create / activate / populate NAME"
    echo -e "-d NAME  deactivate virtual environment 'NAME'"
    echo -e "-D NAME  delete virtual environment 'NAME'"
}

# Check for missing venv NAME for commands that require it
function _setv_checkArg()
{
    if [[ "$1" =~ ^- ]]; then
        return $setv_fail
    fi
}

# Reset a user prompt after deactivating or deleting a venv
function _setv_resetPrompt()
{
    export PS1=$old_PS1
}

# Determine whether or not a venv is active
function _setv_invenv()
{
    # INVENV=$(python3 -c 'import sys; print ("1" if sys.base_prefix != sys.prefix else "0")')
    INVENV=$(python3 -c 'import os;  print ("1" if "VIRTUAL_ENV" in os.environ else "0")')
}

# Creates a new virtual environment
function _setv_create()
{
    local func="`echo ${FUNCNAME[0]} | cut -d _ -f 3 | sed "s/^ //g"`"

    if [ -z $1 ]; then
        echo "$prog: $func: no name provided to create a virtual environment"
        return $setv_fail
    elif [ ! -d $SETV_VIRTUAL_ENV_DIR/$1 ]; then
        echo "$prog: $func: new virtual environment '$1' at $SETV_VIRTUAL_ENV_DIR"

        # for python >= v3.9, upgrade dependencies (pip, setuptools) in place with '--upgrade-deps'
        _upgrade_deps=""
        [ "$_version_check" -eq "1" ] && _upgrade_deps="--upgrade-deps"
        python3 -m venv $_upgrade_deps $SETV_VIRTUAL_ENV_DIR/$1
        echo "$prog: $func: successfully created virtual environment '$1'" ; echo
    else
        echo "$prog: $func: virtual environment $SETV_VIRTUAL_ENV_DIR/$1 already exists."
    fi
}

# Activates a new virtual environment
function _setv_activate()
{
    local func="`echo ${FUNCNAME[0]} | cut -d _ -f 3 | sed "s/^ //g"`"

    if [ -z $1 ]; then
        echo "$prog: $func: must specify a virtual environment to activate"
        return $setv_fail
    fi

    if [ -d $SETV_VIRTUAL_ENV_DIR/$1 ]; then
        echo "$prog: $func: activating virtual environment 'name': $1"
        source ${SETV_VIRTUAL_ENV_DIR}/${1}/bin/activate
        echo "$prog: $func: successfully activated virtual environment '$1'" ; echo
        _setv_invenv
    else
        echo "$prog: $func: virtual environment '$SETV_VIRTUAL_ENV_DIR/$1' doesn't exist; create it first"
        return $setv_fail
    fi
}

# Deactivate a virtual environment
function _setv_deactivate()
{
    local func="`echo ${FUNCNAME[0]} | cut -d _ -f 3 | sed "s/^ //g"`"

    if [ -z $1 ]; then
        echo "$prog: $func: specify a virtual environment to deactivate"
        return $setv_fail
    fi

    # no virtual environment with specified name
    if [ ! -d $SETV_VIRTUAL_ENV_DIR/$1 ]; then
        echo "$prog: $func: no virtual environment named '$1'"
        return $setv_fail
    fi

    _setv_invenv
    if [ $INVENV == 1 ]; then
        echo "$prog: $func: deactivating virtual environment '$1'"
        deactivate
        _setv_invenv
    else
        echo "$prog: $func: no active virtual environment"
        return $setv_fail
    fi
}

# Check argument list (from '-p' or '-N') for a specified requirements file
function _setv_rqmts_file()
{
    local args=("$@")

    for ((i = 0; i < ${#args[@]}; i++)); do
        if [ "${args[$i]}" == "-r" ]; then
            _rqmt_file="${args[((i=i + 1))]}"
        fi
    done
    
    return
}

# Populate a virtual environment with specified packages
function _setv_populate()
{
    local func="`echo ${FUNCNAME[0]} | cut -d _ -f 3 | sed "s/^ //g"`"

    if [ -z $1 ]; then
        echo "$prog: $func: must specify a virtual environment to populate"
        return $setv_fail
    fi

    # virtual environment must exist first
    if [ ! -d $SETV_VIRTUAL_ENV_DIR/$1 ]; then
        echo "$prog: $func: no virtual environment named '${1}', create and activate it first"
        return $setv_fail
    elif [ $INVENV == 1 ]; then
        echo "$prog: $func: populating virtual environment '$1'"
        _rqmt_file=${_rqmt_file:-$RQMT_FILE}
        echo "   ...using requirements file '$_rqmt_file'"
        echo "   ...installing required python packages"
        pip3 install --no-cache-dir -r $_rqmt_file
        echo ; echo "Installed packages:" 
        pip3 list
    else
        echo "$prog: $func: virtual environment '$SETV_VIRTUAL_ENV_DIR/$1' must be activated before populating it"
        return $setv_fail
    fi

    # unset requirements file for any subsequent venv populate requests
    _rqmt_file=""
}

# Deletes a virtual environment
function _setv_delete()
{
    local func="`echo ${FUNCNAME[0]} | cut -d _ -f 3 | sed "s/^ //g"`"

    if [ -z $1 ]; then

        echo "$prog: $func: no virtual environment specified to delete"
        return $setv_fail
    else
        if [ -d $SETV_VIRTUAL_ENV_DIR/$1 ]; then
            while true; do
                read -p "Really delete virtual environment '$1' (y/N)? " yes_no
                case $yes_no in
                    y | Y)
                            _setv_deactivate $1 &> /dev/null
                            rm -rf $SETV_VIRTUAL_ENV_DIR/$1
                            _setv_invenv
                            echo "$prog: $func: virtual environment '$1' deleted"
                            break
                            ;;
                    n | N) 
                            echo "Not deleting virtual environment '$1'"
                            break
                            ;;
                    *)
                            ;;
                esac
            done
        else
            echo "$prog: $func: no virtual environment named '$1'"
            return $setv_fail
        fi
    fi

   _setv_resetPrompt
}

# Set / reset SETV_VIRTUAL_ENV_DIR
function _setv_Home()
{
    local func="`echo ${FUNCNAME[0]} | cut -d _ -f 3 | sed "s/^ //g"`"

    if [ -z $1 ]; then
        echo "$prog: $func: specify a virtual environment home location"
        return $setv_fail
    else
        echo "$prog: $func: creating virtual environment home location '$1'"
        mkdir -pv $1
        export SETV_VIRTUAL_ENV_DIR=$1
    fi
}

# Lists all virtual environments
function _setv_list()
{
    echo -e "Virtual environments available in ${SETV_VIRTUAL_ENV_DIR}:\n"
    for venv in $(ls -l "${SETV_VIRTUAL_ENV_DIR}" | egrep '^d' | awk -F " " '{print $NF}')
    do
        echo $venv
    done
}

export -f _setv_activate
export -f _setv_create
export -f _setv_deactivate
export -f _setv_delete
export -f _setv_Home
export -f _setv_help_
export -f _setv_populate
export -f _setv_list
export -f _setv_invenv
export -f _setv_resetPrompt
export -f _setv_checkArg
export -f _setv_rqmts_file

# Calls bash build-in 'complete' function, storing the rules for future use.
complete  -F _setvcomplete_ setv
