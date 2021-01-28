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

function _setv_help() {
    echo
    echo "Usage: setv options <venv>"
    echo Optional arguments:
    echo -e "  --help  help (show this information)"
    echo -e "  --list  list available virtual environments\n"

    echo -n "  --install [--package <pkg-file>] venv"
        echo -e "  install (optionally from <pkg-file>) and activate 'venv'"
    echo -n "  --update [--package <pkg-file>] venv"
        echo -e "  update (optionally from <pkg-file>) 'venv'"
    echo -e "  --clone venv clone   clone virtual environment 'venv' into 'clone'"
    echo -e "  --delete venv  delete virtual environment 'venv'"

    echo -n "  --venvdir <dir>  specify virtual environment home location"
    echo -e " (current: $SETV_VIRTUAL_ENV_DIR)\n"
}

# Check for missing venv NAME for commands that require it
function _setv_checkArg()
{
    local arg=$1

    # missing argument
    if [[ -z $arg ]]; then
        return $setv_fail
    fi

    # argument starts with a '-' ==> command switch
    if [[ "$arg" =~ ^- ]]; then
        return $setv_fail
    fi
    
    return
}

# Determine whether or not a venv is active
function _setv_invenv()
{
    # INVENV=$(python3 -c 'import sys; print ("1" if sys.base_prefix != sys.prefix else "0")')
    INVENV=$(python3 -c 'import os;  print ("1" if "VIRTUAL_ENV" in os.environ else "0")')
    [[ ! -z $VIRTUAL_ENV && $INVENV -eq 1 ]] && _curr_venv=`basename $VIRTUAL_ENV` || _curr_venv=""
}

function _setv_venv_exists()
{
    local func="`echo ${FUNCNAME[0]} | cut -d _ -f 3 | sed "s/^ //g"`"
    local venv=$1

    [[ -d $SETV_VIRTUAL_ENV_DIR/$venv ]] && return $setv_fail
}

# Creates a new virtual environment
function _setv_create()
{
    local func="`echo ${FUNCNAME[0]} | cut -d _ -f 3 | sed "s/^ //g"`"
    local venv=$1

    if [ -z $venv ]; then
        echo "$prog: $func: no name provided to create a virtual environment"
        return $setv_fail
    elif [ ! -d $SETV_VIRTUAL_ENV_DIR/$venv ]; then
        echo "$prog: $func: new virtual environment '$venv'"

        # for python >= v3.9, upgrade dependencies (pip, setuptools) in place with '--upgrade-deps'
        _upgrade_deps=""
        if [ $_version == 1 ]; then
              _upgrade_deps="--upgrade-deps"
        fi

        python3 -m venv $_upgrade_deps $SETV_VIRTUAL_ENV_DIR/$venv
        echo "$prog: $func: successfully created venv '$venv'" ; echo
    else
        echo "$prog: $func: venv '$venv' already exists."
    fi
}

# Activates a new virtual environment
function _setv_activate()
{
    local func="`echo ${FUNCNAME[0]} | cut -d _ -f 3 | sed "s/^ //g"`"
    local venv=$1

    if [ -z $venv ]; then
        echo "$prog: $func: must specify a venv to activate"
        return $setv_fail
    fi

    if [ -d $SETV_VIRTUAL_ENV_DIR/$venv ]; then
        if [ ! -z $_curr_venv ]; then
            if [ "$venv" != "$_curr_venv" ]; then
                echo -ne "$prog: $func: deactivating current venv ('$_curr_venv')..." && \
                _setv_deactivate $_curr_venv >& /dev/null && echo " done"
            else
                echo "$prog: $func: venv '$venv' ($_curr_venv) is already active"
                return
            fi
        fi

        echo -ne "$prog: $func: activating venv '$venv'..."
        source $SETV_VIRTUAL_ENV_DIR/$venv/bin/activate && echo -e " done\n"
        _setv_invenv
    else
        echo "$prog: $func: venv '$venv' doesn't exist; create it first"
        return $setv_fail
    fi
}

# Deactivate a virtual environment
function _setv_deactivate()
{
    local func="`echo ${FUNCNAME[0]} | cut -d _ -f 3 | sed "s/^ //g"`"
    local venv=$1

    if [ -z $venv ]; then
        echo "$prog: $func: specify a virtual environment to deactivate"
        return $setv_fail
    fi

    # no virtual environment with specified name
    if [ ! -d $SETV_VIRTUAL_ENV_DIR/$venv ]; then
        echo "$prog: $func: no venv named '$venv'"
        return $setv_fail
    fi

    _setv_invenv
    if [ $INVENV == 1 ]; then
        if [ $_curr_venv != $venv ]; then
            echo "$prog: $func: only the currently active venv ('$_curr_venv') can be deactivated"
            return $setv_fail
        else
            echo "$prog: $func: deactivating currently active venv '$venv'"
            deactivate
            _setv_invenv
        fi
    else
        echo "$prog: $func: no active venv"
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
    local venv=$1

    if [ -z $venv ]; then
        echo "$prog: $func: must specify a venv to populate"
        return $setv_fail
    fi

    # virtual environment must exist first
    if [ ! -d $SETV_VIRTUAL_ENV_DIR/$venv ]; then
        echo "$prog: $func: no venv named '${1}', create and activate it first"
        return $setv_fail
    elif [ $INVENV == 1 ]; then
        echo "$prog: $func: populating venv '$venv'"
        pip install --upgrade pip

        pip3 install --no-cache-dir -r $RQMT_FILE
        if [ -n "${_rqmt_file}" ]; then
            echo "   $func: ...using requirements file '$_rqmt_file'"
            echo "   $func: ...installing required python packages"
            pip3 install --no-cache-dir -r $_rqmt_file
        fi

        echo ; echo "Installed packages:" 
        pip3 list
        echo
    else
        echo "$prog: $func: venv '$SETV_VIRTUAL_ENV_DIR/$venv' must be activated before populating it"
        return $setv_fail
    fi

    # unset requirements file for any subsequent venv populate requests
    _rqmt_file=""
}

# Clone a virtual environment
function _setv_clone()
{
    local func="`echo ${FUNCNAME[0]} | cut -d _ -f 3 | sed "s/^ //g"`"
    local venv=$1 clone=$2

    # can't clone to self
    if [ "$venv" == "$clone" ]; then
        echo "$prog: $func: cannot clone self: '$1' to '$2'"
        return $setv_fail
    fi

    if [ ! -d $SETV_VIRTUAL_ENV_DIR/$venv ]; then
        echo "$prog: $func: venv '$venv' doesn't exist"
        return $setv_fail
    fi

    if [ -d $SETV_VIRTUAL_ENV_DIR/$clone ]; then
        echo "$prog: $func: venv '$clone' already exists"
        return $setv_fail
    fi

    mkdir -p /tmp/$clone && pip3 freeze > /tmp/$clone/$clone.txt
    echo -n "$prog: $func: cloning venv '$venv' to venv '$clone'"
    echo -ne "..." && _setv_create $clone &> /dev/null
    echo -ne "...." && _setv_activate $clone &> /dev/null
    echo -ne "....." && _setv_populate $clone -r /tmp/$clone/$clone.txt &> /dev/null
    echo -e " done\n"
    rm -rf /tmp/$clone

    # reactivate original venv
    _setv_activate $venv &> /dev/null

    return
}

# Deletes a virtual environment
function _setv_delete()
{
    local func="`echo ${FUNCNAME[0]} | cut -d _ -f 3 | sed "s/^ //g"`"
    local venv=$1

    if [ -z $venv ]; then

        echo "$prog: $func: no venv specified to delete"
        return $setv_fail
    else
        if [ -d $SETV_VIRTUAL_ENV_DIR/$venv ]; then
            local _str="'$venv'"
            if [ "$1" == "_curr_venv" ]; then
                _str="'$1' (currently active)"
            fi

            while true; do
                # read -p "Really delete virtual environment '$1' (y/N)? " yes_no
                read -p "Really delete venv $_str (y/N)? " yes_no
                case $yes_no in
                    y | Y)
                            [[ $INVENV == 1 ]] && _setv_deactivate $1 &> /dev/null
                            # if in the venv structure, chg dir before deleting else end up in a nonexistent dir
                            [[ "${PWD##${SETV_VIRTUAL_ENV_DIR}}" != "${PWD}" ]] && cd $SETV_VIRTUAL_ENV_DIR
                            rm -rf $SETV_VIRTUAL_ENV_DIR/$1
                            _setv_invenv
                            echo "$prog: $func: venv '$venv' deleted"
                            break
                            ;;
                    n | N) 
                            echo "Not deleting venv '$venv'"
                            break
                            ;;
                    *)
                            ;;
                esac
            done
        else
            echo "$prog: $func: no venv named '$venv'"
            return $setv_fail
        fi
    fi
}

# Set / reset SETV_VIRTUAL_ENV_DIR
function _setv_vdir()
{
    local func="`echo ${FUNCNAME[0]} | cut -d _ -f 3 | sed "s/^ //g"`"
    local vdir=$1

    if [ -z $vdir ]; then
        echo "$prog: $func: specify a virtual environment home location"
        return $setv_fail
    else
        echo "$prog: $func: setting virtual environment home location to '$vdir'"
        mkdir -pv $vdir
        export SETV_VIRTUAL_ENV_DIR=$vdir
    fi
}

# Lists all virtual environments
function _setv_list()
{
    local _star=""

    echo -e "Virtual environments available in ${SETV_VIRTUAL_ENV_DIR}:\n"
    for venv in $(ls -l "${SETV_VIRTUAL_ENV_DIR}" | egrep '^d' | awk -F " " '{print $NF}')
    do
        [[ "$venv" == "$_curr_venv" ]] && _star=" (*)"
        echo $venv $_star
        _star=""
    done
}

export -f _setv_activate
export -f _setv_create
export -f _setv_deactivate
export -f _setv_delete
export -f _setv_vdir
export -f _setv_help
export -f _setv_populate
export -f _setv_clone
export -f _setv_list
export -f _setv_invenv
export -f _setv_venv_exists
export -f _setv_checkArg
export -f _setv_rqmts_file

# Calls bash build-in 'complete' function, storing the rules for future use.
complete  -F _setvcomplete_ setv
