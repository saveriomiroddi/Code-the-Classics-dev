#!/bin/bash

set -o pipefail
set -o errexit
set -o nounset
set -o errtrace
shopt -s inherit_errexit

c_reference_project=cavern-macroquad-naive
c_help="\
Usage: $(basename "$0") <project_name-suffix>

Actions performed:

- creates a new rust project, using \`$c_reference_project\` as template;
- moves the original project to the shared resources dir;

Note that this yields one copy of the source code under resources, and another copy on the new project.

The suffix is for the new project, and it's optional; it supports dashes."

v_original_project=
v_new_project=

function decode_cmdline_args {
  local params
  params=$(getopt --options h --long help --name "$(basename "$0")" -- "$@")

  eval set -- "$params"

  # DON'T FORGET THE `shift` commands and the `--` case.
  # Rigorously, one should add the '*' case (internal error), but it's not required.
  #
  while true; do
    case $1 in
      -h|--help)
        echo "$c_help"
        exit 0 ;;
      --)
        shift
        break ;;
    esac
  done

  if [[ $# -ne 1 ]]; then
    echo "$c_help"
    exit 1
  fi

  v_original_project=${1%%-*}
  v_new_project=$1
}

function move_to_root_dir {
  cd "$(dirname "$0")/.."
}

function check_project_name {
  if [[ ! -d original_code/$v_original_project-master && ! -d resources/$v_original_project ]]; then
    >&2 echo 'Project original code not found!'
    exit 1
  fi
}

function add_project {
  cargo new "$v_new_project"

  rsync -av --relative \
    "$c_reference_project/./Cargo.toml" \
    "$c_reference_project/./rust-toolchain" \
    "$c_reference_project/./.cargo" \
    "$c_reference_project/./.vscode" \
    "$v_new_project/"

  perl -i -pe \
    "s/$c_reference_project/$v_new_project/" \
    "$v_new_project/Cargo.toml" \
    "$v_new_project/.vscode/launch.json"

  # At this stage, the file can be already under `resources/`, or not.
  # It could also be under previous ports of the same game, so we can't just glob the way.
  #
  find resources original_code -name "$v_original_project.py" -exec cp -v {} "$v_new_project/src/" \;

  # At this stage, this could be broken, but that's fine.
  #
  ln -s "../resources/$v_original_project" "$v_new_project/resources"

  git ca -m "Add ${v_new_project^} project"
}

function move_original_code {
  mv "original_code/$v_original_project-master" "resources/$v_original_project"
  sed -i '1i #!/usr/bin/env python3' "resources/$v_original_project/$v_original_project.py"
  chmod 755 "resources/$v_original_project/$v_original_project.py"
  git ca -m "${v_new_project^}: Move original project inside the shared resources dir"
}

decode_cmdline_args "$@"
move_to_root_dir
check_project_name
add_project
if [[ ! -d resources/$v_original_project ]]; then
  move_original_code
fi