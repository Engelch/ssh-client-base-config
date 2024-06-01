#!/usr/bin/env bash

# code from ConfigShell, inserted here as setup of ConfigShell cannot be expected at such an early stage #################

# reverse to write a message in reverse mode
function reverse() {
  if [ "$TERM" = "xterm" ] || [ "$TERM" = "vt100" ] || [ "$TERM" = "xterm-256color" ] || [ "$TERM" = "screen" ] ; then
      tput smso ; echo "$@" ; tput rmso
  else
    echo "$@"
  fi
}

function err()                          { echo "$*" 1>&2; }                                         # just write to stderr
function err4()                         { echo "    $*" 1>&2; }                                     # just write to stderr
function error()                        { reverse 'ERROR:'"$@" 1>&2;  return 0; }                   # write ERROR:<<msg>> to stderr
function errorExit()                    { EXITCODE="$1" ; shift; error "$*" ; exit "$EXITCODE"; }   # write ERROR::<$2...>> so stderr and exit with code $1
function exitIfBinariesNotFound()       { for file in "$@"; do command -v "$file" &>/dev/null || errorExit 253 binary not found: "$file"; done }

# app-specific code ###############################################################################################

## testInstallSshLocation exit if the location of this script is not in ~/.ssh/
# TRAP EXIT
# EXIT 10 11 12
function testInstallSshLocation() {
    cd "$(dirname $0)" || errorExit 10 "cannot switch to $(dirname $0)"
    local touchFile="./rand-$RANDOM-$$"
    trap "/bin/rm -f $touchFile" EXIT
    touch "$touchFile" || errorExit 11 "cannot create touchfile $touchFile"
    ! [ -f ~/.ssh/"$touchFile" ] && errorExit 12 "touch-file does not seem to be created under ~/.ssh/"
    echo ok install-ssh.sh is reachable as ~/.ssh/install-ssh.sh
    return 0
}

# checkRequirements checks if any ssh-xxxx-config repositories are s-linked to ~/.ssh
# EXIT 20 21
function checkRequirements() {
    [ "$(/bin/ls -1 Config*.d Keys*.d 2>/dev/null | wc -l)" -eq 0 ] && errorExit 20 "No ssh-*-config repositories linked to ssh-generic"
    for file in require__* ; do
        [ "$file" = 'require__*' ] && echo "ok no requirements" &&  break
        local target="$(echo $file | sed 's/.*__//')"
        ! [ -e "$target" ] && errorExit 21 "target $target not found for requirement $file"
        echo "ok requirement $file"
    done
}

# setupDefaultId
# NO EXIT
function setupDefaultId() {
    local numCfgs="$(find -L . -depth 2 | grep '^\./Keys\..*.d' | grep '/id_rsa$' | wc -l)"
    local cfg=''
    [ "$numCfgs" -eq 0 ] && echo "ok no $1 configurations" && return 0
    echo ok "default id configurations found in Keys.\*.d: $numCfgs"
    if [ "$numCfgs" -eq 1 ] ; then
        echo ok setup id_rsa configuration as only one found
        cfg="$(find -L . -depth 2 | grep '^\./Keys\..*.d' | grep '/id_rsa$')"
        ln -fsv "$cfg" "$1"
    else
        select cfg in $(find -L . -depth 2 | grep '^\./Keys\..*.d' | grep '/id_rsa$') ; do
            ln -sfv "$cfg" .
            echo ok "$cfg chosen"
            break
        done
    fi
    # check for id_rsa.pub and id_rsa-cert.pub
    dirCfg="$(dirname "$cfg")"
    [ -e "$dirCfg/id_rsa.pub" ] && echo "ok found $dirCfg/id_rsa.pub, linking" && ln -fs "$dirCfg/id_rsa.pub" .
    [ -e "$dirCfg/id_rsa-cert.pub" ] && echo "ok found $dirCfg/id_rsa-cert.pub, linking" && ln -fs "$dirCfg/id_rsa-cert.pub" .
}

# setupCompletion
# EXIT 40
function setupCompletion() {
    if [ -e completion.lst ] ; then
        echo ok completion.lst found.
        read -e -N 1 -p 'Do you want to replace completion.lst [Yn]?' -i y answer
        if [[ "$answer" =~ [yY] ]] ; then
            echo ok replacing existing completion.lst file
            /bin/rm -f completion.lst
            ssh-createCompletionList || errorExit 40 creating completion list
        else
            echo ok not replacing existing completion.lst file
        fi
    else
        echo ok no completion.lst found, creating it.
        ssh-createCompletionList || errorExit 40 creating completion list
    fi
    echo "ok number of hosts in completion file completion.lst: $(wc -l completion.lst | awk '{print $1}')"
}

# setupAwsGnupgGitConfig
# EXIT 30, 31, 32
function setupAwsGnupgGitConfig() {
    [ "$1" != gnupg ] && [ "$1" != aws ] && [ "$1" != gitconfig ] && errorExit 30 "setupAwsGnupgGitConfig called with 1st argument not supported, being $1"
    # check how many configuration exist by s-linked ssh-modules
    local numCfgs="$(find -L . -depth 2 | grep '^\./Other\.' | grep "/$1$" | wc -l)"
    [ "$numCfgs" -eq 0 ] && echo "ok no $1 configurations detected" && return 0 # no cfg, return
    echo "ok number of $1 configurations found in Other.*.d: $numCfgs"
    [ -e "$1" ] && { echo ok detected existing ~/.ssh/$1, deleting ; /bin/rm -f "$1" ; } # delete an already existing configuration setup ~/.ssh/"$1"
    if [ "$numCfgs" -eq 1 ] ; then
        echo "ok setup $1 configuration as only one found"
        cfg="$(find -L . -depth 2 | grep '^\./Other\.' | grep "/$1$")"
        ln -sv "$cfg" "$1" || errorExit 31 "creating s-link like ln -s $cfg $1"
    else
        select cfg in $(find -L . -depth 2 | grep '^\./Other\.' | grep "/$1$") ; do
            ln -sv "$cfg" "$1" || errorExit 31 "creating s-link like ln -s $cfg $1"
            echo "ok $cfg chosen, configured"
            break
        done
    fi
    # fix ~/."$1" by always resetting it and moving existing configuration to ."$1".org
    cd
    [ -L ."$1" ] && { echo ok s-link detected .$1 ; /bin/mv -f ".$1" ".$1.org" || { echo "ok deleting, cannot be moved .$1" ; /bin/rm -f ".$1" ; } ;  }  # existing ~/."$1" found, if same as ."$1".org, delete it
    [ -e ".$1" ] && { echo "not ok .$1 is not an s-link"
        [ -L ".$1.org" ] && /bin/rm -f ".$1.org"
        /bin/mv -f ".$1" ".$1.org" || errorExit 32 "cannot move .$1"
        echo "ok fixed .$1 by moving it to .$1.org"
    }
    ln -sv ".ssh/$1" ".$1"
    cd - > /dev/null
}

# execution in parallel in not expected
# All called functions are supposed to execute with CWD = ~/.ssh/
# The ssh-modules can only contain: Other.xxx.d, Keys.xxx.d, and optional require__Config.<<repo>>.d__Keys.<<requiredRepo>>.d
# At least one ssh-module is supposed to be s-linked to the ssh-generic ssh main element.
# EXIT 1 + sub-exits
function main() {
    set -u

    exitIfBinariesNotFound sed          # EXIT 253
    testInstallSshLocation              # check if install-ssh.sh is from ~/.ssh. Otherwise, EXIT 10 11 12
    cd ~/.ssh || errorExit 1 "cannot change directory to ~/.ssh"
    checkRequirements                   # check if ssh-...-config inter-dependencies are met. Else, EXIT 20 21

    setupDefaultId                      # NO EXIT
    setupAwsGnupgGitConfig aws          # EXIT 30, 31, 32
    setupAwsGnupgGitConfig gnupg        # EXIT 30, 31, 32
    setupAwsGnupgGitConfig gitconfig    # EXIT 30, 31, 32
    setupCompletion                     # EXIT 40
}

main "$@"
