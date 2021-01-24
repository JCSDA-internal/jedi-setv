# jedi-setv
Python virtual environment (venv) tools

* check out jedi-stack branch `feature/venv`
* verify the `build_stack.sh` specifies:
  * `build_lib SETV setv jcsda-internal 0.1`
* verify your stack `config/choose_modules.sh` contains
  * `export          STACK_BUILD_SETV=Y`
  * you may wish to unset other modules (set to `=N`)
* `build_stack.sh <config>`

* module load setv
* export SETV_VIRTUAL_ENV_DIR=\<path to where virtual envs will be created\>
  * defaults to `$HOME`
* `setv -h`
