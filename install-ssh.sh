#!/usr/bin/env bash

# reverse helps to write a message in reverse mode
function reverse() {
  if [ "$TERM" = "xterm" ] || [ "$TERM" = "vt100" ] || [ "$TERM" = "xterm-256color" ] || [ "$TERM" = "screen" ] ; then
      tput smso ; echo "$@" ; tput rmso
  else
    echo "$@"
  fi
}

function err()          { echo "$*" 1>&2; }                                         # just write to stderr
function err4()         { echo "    $*" 1>&2; }                                     # just write to stderr
function error()        { reverse 'ERROR:'"$@" 1>&2;  return 0; }                   # write ERROR:<<msg>> to stderr
function errorExit()    { EXITCODE="$1" ; shift; error "$*" ; exit "$EXITCODE"; }   # write ERROR::<$2...>> so stderr and exit with code $1

# sLinkEndsWith sLinkName subStringTheDestinationOfSLinkShouldEndWith
# The last character in the match string can be a / (automatically added by this function).
function sLinkEndsWith() {
    [ -z "$1" ] && return 1
    [ -L "$1" ] || return 2
    [[ "$(ls -ld "$1" | awk '{ print $NF }')" =~ .*"$2"/? ]] && return 0
    return 3
}

##########

## testInstallSshLocation exit if the location of this script is not in ~/.ssh/
# TRAP EXIT
# EXIT 10 11 12
function testInstallSshLocation() {
    cd "$(dirname $0)" || errorExit 10 "cannot switch to $(dirname $0)"
    local touchFile="./rand-$RANDOM-$$"
    trap "/bin/rm -f $touchFile" EXIT
    touch "$touchFile" || errorExit 11 "cannot create touchfile $touchFile"
    ! [ -f ~/.ssh/"$touchFile" ] && errorExit 12 "touch-file does not seem to be created under ~/.ssh/"
    return 0
}

function oldCode() {

    # EXIT 1
    # EXIT 2
    [ ! -e .ssh ] && errorExit 1 But, .ssh does not seem to exist
    [ -L .ssh ] && err ssh is an s-linked directory && cd .ssh > /dev/null || errorExit 2 Could not jump to .ssh
    cd # previous cd was successful, let's move back

    # an array of tuples would be nice
    if sLinkEndsWith .aws ssh/aws ; then 
        err .aws seems to be correct
    else
        err fixing .aws
        [ -f .aws ] && mv -f .aws .aws.org
        ln -s ~/.ssh/aws .aws
    fi

    if [ -f .ssh/dot.gitconfig ] ; then
        if sLinkEndsWith .gitconfig .ssh/dot.gitconfig ; then
            err .gitconfig seems to be correct
        else
            err fixing .gitconfig
            [ -f .gitconfig ] && mv -f .gitconfig .gitconfig.org
            ln -s ~/.ssh/dot.gitconfig .gitconfig
        fi
    else 
        err Did not find .ssh/dot.gitconfig, please run git init or s-link it from one of your git-submodules and run this install-ssh.sh again.
    fi

    if sLinkEndsWith .gnupg .ssh/gnupg ; then
        err .gnupg seems to be correct
    else
        err fixing .gnupg
        [ -f .gnupg ] && mv -f .gnupg .gnupg.org
        ln -s  ~/.ssh/gnupg .gnupg
    fi

    [ ! -d bin ] && err creating bin directory && mkdir bin
}

## execution in parallel in not expected
function main() {
    set -u
    
    testInstallSshLocation # check if install-ssh.sh is from ~/.ssh. Otherwise, EXIT 10 11 12
    cd ~/.ssh || errorExit 1 "cannot change directory to ~/.ssh"
    [ "$(/bin/ls -1 Config*.d Keys*.d 2>/dev/null | wc -l)" -eq 0 ] && errorExit 2 "No ssh-*-config repositories linked to ssh-generic"
    for file in require__* ; do
        [ "$file" = 'require__*' ] && echo "ok no requirements" &&  break
        local target="$(echo $file | sed 's/.*__//')"
        ! [ -f "$target" ] && errorExit 3 "target $target not found for requirement $file"
        echo "ok requirement $file"
    done
}


main "$@"