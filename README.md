# jedi-setv
Python virtual environment (venv) tools

* check out jedi-stack branch `feature/venv`
* verify the `build_stack.sh` specifies:
  * `build_lib SETV setv jcsda-internal 0.1`
* verify your stack `config/choose_modules.sh` contains
  * `export          STACK_BUILD_SETV=Y`
  * you may wish to unset other modules (set to `=N`)
* `build_stack.sh <config>`

* `module load setv`


## How to create a virtual environment (venv)
A virtual environment is a Python tool for dependency management and project isolation. They allow Python site packages (third party libraries) to be installed locally in an isolated directory for a particular project, as opposed to being installed globally (i.e. as part of a system-wide Python configuration).

Virtual environments provide a simple solution to a host of potential problems. In particular, they help you to:

  - resolve dependency issues by allowing you to use different versions of a package for different projects. For example, you could use _Package A v2.7_ for _Project X_ and _Package A v1.3_ for _Project Y_
  - make your project self-contained and reproducible by capturing all package dependencies in a requirements file
  - install packages on a host on which you do not have admin privileges
  
The JEDI module `setv` is a tool to create and manage virtual environments. As with other JEDI modules, it is loaded as:

`module load setv`

The `--help` option to setv provides a list of available commands:

```
% setv --help

Usage: setv options <venv>
Optional arguments:
  --help  help (show this information)
  --list  list available virtual environments

  --activate venv  activate 'venv'
  --install [--package <pkg-file>] venv  install (optionally from <pkg-file>) and activate 'venv'
  --update --package <pkg-file> venv  update 'venv' from <pkg-file>
  --delete venv  delete virtual environment 'venv'
  --venvdir <dir>  specify virtual environment home location (current: $HOME)
```

The environment variable **SETV_VIRTUAL_ENV_DIR** controls where a venv is created. By default, it's value is set to a user's $HOME. Change the value of this variable if you wish to create a venv in a directory other than $HOME; this location can be changed as:

```
% setv --venvdir <dir>
```

where _\<dir\>_ is the location you choose to host your venv(s).

To create a venv, enter:

```
% setv --install <venv>
```

where _\<venv\>_ is what you wish to call your venv. A venv is created, minimally populated with utilities necessary to get started, and activated. At this point, you're working within the virtual environment _\<venv\>_ that you installed.
 
An optional `<pkg-file>` may be specified when installing a venv; a package file is formatted as a [python requirements file](https://pip.pypa.io/en/latest/reference/pip_install/#requirements-file-format), and will install the specified python packages into your venv.

Adding more  Python packages to a venv may be accomplished by updating a venv; use the `--update` switch:

```
% setv --update --package <pkg-file> <venv>
```

The `--package` switch and `<pkg-file>` argument are required; as with `--install`, the specified file is formatted as a [python requirements file](https://pip.pypa.io/en/latest/reference/pip_install/#requirements-file-format).

You may also specify, in lieu of a pkg-file, one of two special labels:

  - ewok
  - r2d2
  
These labels refer to module-specific package files, and install _ewok_ and _r2d2_ python dependencies, respectively. For example:

```
% setv --update --package ewok <venv>
```

A venv may deleted; deleting a venv removes all traces of the venv, and it's no longer available for use. To delete a venv, enter:

```
% setv --delete <venv>
```

Working within a virtual environment does not constrain you from otherwise manipulating your python environment; rather, it means that any changes (additions, deletions, etc.) to your python environment occur **_only_** within the venv within which you're working, and do not impact your broader working environment.
