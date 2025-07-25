#!/usr/bin/env zsh
#
# This is a implementation of per-project history for Zsh
#
# Copyright (c) 2014 Jim Hester
# Copyright (c) 2025 Ivan Cukic
#
# This software is provided 'as-is', without any express or implied warranty.
# In no event will the authors be held liable for any damages arising from the
# use of this software.
#
# Permission is granted to anyone to use this software for any purpose,
# including commercial applications, and to alter it and redistribute it
# freely, subject to the following restrictions:
#
# 1. The origin of this software must not be misrepresented; you must not claim
# that you wrote the original software. If you use this software in a product,
# an acknowledgment in the product documentation would be appreciated but is
# not required.
#
# 2. Altered source versions must be plainly marked as such, and must not be
# misrepresented as being the original software.
#
# 3. This notice may not be removed or altered from any source distribution..
#
################################################################################

#-------------------------------------------------------------------------------
# configuration, the base under which the project histories are stored
#-------------------------------------------------------------------------------

[[ -z $HISTORY_BASE ]] && HISTORY_BASE="$HOME/.zsh_project_history"
[[ -z $HISTORY_START_WITH_GLOBAL ]] && HISTORY_START_WITH_GLOBAL=false
[[ -z $PER_PROJECT_HISTORY_TOGGLE ]] && PER_PROJECT_HISTORY_TOGGLE='^G'


if [[ -z "${PER_PROJECT_HISTORY_TAGS}" ]]; then
  declare -a PER_PROJECT_HISTORY_TAGS
  export PER_PROJECT_HISTORY_TAGS=(.git .hg .jj .stack-work .cabal .cargo .envrc .per_project_history)
  declare -r PER_PROJECT_HISTORY_TAGS
  echo "Using the default tags ${PER_PROJECT_HISTORY_TAGS}"
fi

#-------------------------------------------------------------------------------
# toggle global/project history used for searching - ctrl-G by default
#-------------------------------------------------------------------------------

function per-project-history-toggle-history() {
  if [[ $_per_project_history_is_global == true ]]; then
    _per-project-history-set-project-history
    _per_project_history_is_global=false
    zle -I
    echo "using local history"
  else
    _per-project-history-set-global-history
    _per_project_history_is_global=true
    zle -I
    echo "using global history"
  fi
}

autoload per-project-history-toggle-history
zle -N per-project-history-toggle-history
bindkey $PER_PROJECT_HISTORY_TOGGLE per-project-history-toggle-history
bindkey -M vicmd $PER_PROJECT_HISTORY_TOGGLE per-project-history-toggle-history

#-------------------------------------------------------------------------------
# implementation details
#-------------------------------------------------------------------------------

_per_project_history_directory="$HISTORY_BASE${PWD:A}/history"

export ZSH_PROJECT_HISTORY_ACTIVE_DIRECTORY=""

function _per-project-history-directory-tagged() {
  TESTING_DIRECTORY="$1"
  # echo "_per-project-history-directory-tagged ${TESTING_DIRECTORY}/${PER_PROJECT_HISTORY_TAGS}" >&2
  for TAG in ${PER_PROJECT_HISTORY_TAGS}; do
    # echo "Testing for ${TESTING_DIRECTORY}/${TAG}" >&2
    if [[ -e "${TESTING_DIRECTORY}/${TAG}" ]]; then
      # echo "Found ${TESTING_DIRECTORY}/${TAG}" >&2
      return 0
    fi
  done
  return 1
}

function _per-project-history-find-up() {
  CURRENT_DIR="${PWD}"

  while
    _per-project-history-directory-tagged "${CURRENT_DIR}"
    [ $? -ne 0 ]
  do
    CURRENT_DIR="${CURRENT_DIR:h}"
    if [[ "/" = ${CURRENT_DIR} ]]; then
      echo "/"
      return 1
    fi
  done

  echo "${CURRENT_DIR}"
}

function _per-project-history-change-directory() {
  # echo "Tags: ${PER_PROJECT_HISTORY_TAGS}"
  local CURRENT_PROJECT_DIRECTORY=$(_per-project-history-find-up)
  if [[ ${CURRENT_PROJECT_DIRECTORY} = "/" ]]; then
    CURRENT_PROJECT_DIRECTORY="/no_active_project"
  fi

  if [[ "${ZSH_PROJECT_HISTORY_ACTIVE_DIRECTORY}" != "${CURRENT_PROJECT_DIRECTORY}" ]]; then
    echo "Changing the project ${CURRENT_PROJECT_DIRECTORY}" >&2
    _per-project-history-change-directory-impl "${ZSH_PROJECT_HISTORY_ACTIVE_DIRECTORY}" "${CURRENT_PROJECT_DIRECTORY}"
    ZSH_PROJECT_HISTORY_ACTIVE_DIRECTORY="${CURRENT_PROJECT_DIRECTORY}"
  fi
}

function _per-project-history-change-directory-impl() {
  OLD_PROJECT_DIR="$1"
  NEW_PROJECT_DIR="$2"
  _per_project_history_directory="$HISTORY_BASE${NEW_PROJECT_DIR:A}/history"
  mkdir -p ${_per_project_history_directory:h}
  if [[ $_per_project_history_is_global == false ]]; then
    #save to the global history
    fc -AI $HISTFILE
    #save history to previous file
    local prev="$HISTORY_BASE${OLD_PROJECT_DIR:A}/history"
    mkdir -p ${prev:h}
    fc -AI $prev

    #discard previous directory's history
    local original_histsize=$HISTSIZE
    HISTSIZE=0
    HISTSIZE=$original_histsize

    #read history in new file
    if [[ -e $_per_project_history_directory ]]; then
      fc -R $_per_project_history_directory
    fi
  fi
}

function _per-project-history-addhistory() {
  # respect hist_ignore_space
  if [[ -o hist_ignore_space ]] && [[ "$1" == \ * ]]; then
      true
  else
      print -Sr -- "${1%%$'\n'}"
      # instantly write history if set options require it.
      if [[ -o share_history ]] || \
         [[ -o inc_append_history ]] || \
         [[ -o inc_append_history_time ]]; then
          fc -AI $HISTFILE
          fc -AI $_per_project_history_directory
      fi
      fc -p $_per_project_history_directory
  fi
}

function _per-project-history-precmd() {
  if [[ $_per_project_history_initialized == false ]]; then
    _per_project_history_initialized=true

    if [[ $HISTORY_START_WITH_GLOBAL == true ]]; then
      _per-project-history-set-global-history
      _per_project_history_is_global=true
    else
      _per-project-history-set-project-history
      _per_project_history_is_global=false
    fi
  fi
}

function _per-project-history-set-project-history() {
  fc -AI $HISTFILE
  local original_histsize=$HISTSIZE
  HISTSIZE=0
  HISTSIZE=$original_histsize
  if [[ -e "$_per_project_history_directory" ]]; then
    fc -R "$_per_project_history_directory"
  fi
}

function _per-project-history-set-global-history() {
  fc -AI $_per_project_history_directory
  local original_histsize=$HISTSIZE
  HISTSIZE=0
  HISTSIZE=$original_histsize
  if [[ -e "$HISTFILE" ]]; then
    fc -R "$HISTFILE"
  fi
}

mkdir -p ${_per_project_history_directory:h}

#add functions to the exec list for chpwd and zshaddhistory
autoload -U add-zsh-hook
add-zsh-hook chpwd _per-project-history-change-directory
add-zsh-hook zshaddhistory _per-project-history-addhistory
add-zsh-hook precmd _per-project-history-precmd

# set initialized flag to false
_per_project_history_initialized=false
