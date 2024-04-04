#!/bin/bash
# ======================================================================
# 
# INCLUDE file with shared functions
#
# source the script and call cw.help
# 
# ----------------------------------------------------------------------
# 2022-03-09  ahahn        added cw.* functions; others marked as deprecated
# 2022-05-18  ahahn        update cw.lock
# 2023-12-29  ahahn        remove deprecated functions; shellfixes
# 2024-01-23  ahahn        added cw.emoji
# 2024-01-31  ahahn        support for NOCOLOR=1
# 2024-03-05  ahahn        add function cw.helpsection  for help text in scripts
# 2024-04-03  ahahn  2.0   update bashdoc
# 2024-04-04  ahahn  2.1   define NO_COLOR to prevent unbound variable
# ======================================================================

_version=2.1

# Handling of exitocdes
typeset -i rc=0     # the last detected exitcode of a command
typeset -i rcAll=0  # sum of all collected exitcodes

# set -eu -o pipefail

# set a start time
export CW_timer_start
export CW_lockfile

NO_COLOR=${NOCOLOR:-0}

# ----------------------------------------------------------------------

# Show help for available cw.* functions
# no parameter required
function cw.help(){
        local _self="${BASH_SOURCE[0]}"
        local _linestart; typeset -i _linestart
        local _iLine; typeset -i _iLine

        echo
        cw.cecho head "HELP FOR CRONWRAPPER FUNCTIONS * v$_version"
        cw.cecho head "auto generated list of implemented cw.* functions"
        echo
        grep "^function cw\.[a-z][a-z]*" "$_self" | cut -f 2 -d " " | cut -f 1 -d '(' | sort | while read -r fktname
        do 
                cw.cecho cmd "$fktname"
                
                _linestart=$( grep -En "function $fktname *\(" "$_self" | cut -f 1 -d ':' )

                _iLine=$_linestart-1
                while [ $_iLine -gt 0 ]; do
                        line="$( sed -n ${_iLine},${_iLine}p $_self )"
                        if echo "$line" | grep '^#' >/dev/null
                        then                                
                                echo "$line" | grep -v -- "-----" | cut -c 3- | sed "s#^#    #g"
                                _iLine=$_iLine-1
                        else
                                _iLine=0
                        fi
                done | tac
                echo
                echo
        done
}

# ----------------------------------------------------------------------

# Get last exitcode and store it in global var $rc
# no parameter is required
#
# global  integer  $rcAll  sum of retuncodes of all commands
function cw.fetchRc(){
        rc=$?
        local _color

        _color=error
        test $rc = 0 && _color=ok 
        
        echo -n "--> "
        cw.cecho $_color "rc=$rc ($_color)"
        rcAll+=$rc
}

# Execute a given command, show return code (and add it to final exit code)
# param   string  command line to execute 
function cw.exec() {
        echo $*
        cw.color cmd 
        $*
        cw.fetchRc

}

# Show a given emoji if its display is supported
#
# Example
#   echo $( cw.emoji "📜" )License: GNU GPL 3.0
#
# global  integer  $NO_COLOR  value 1 means: no color please; see http://no-color.org/
#
# param   string  emoji to show
# param   string  alternative text for NO_COLOR=1 output
function cw.emoji() {
        if [ "$NO_COLOR" != "1" ]; then
                test "$(echo -ne '\xE0\xA5\xA5' | wc -m)" -eq 1 && echo "$1 "
        else 
                echo "$2"
        fi
}

# Sleep for a random time
#
# param  integer  time to randomize in sec
# param  integer  optional: minimal time to sleep in sec; default: 0
function cw.randomsleep(){
        local _iRnd; typeset -i _iRnd=$1
        local _iMintime; typeset -i _iMintime=$2
        local _iSleep; typeset -i _iSleep=$(($RANDOM%$_iRnd+$_iMintime))
        echo Sleeping for $_iSleep sec ...
        sleep $_iSleep
}

# Get time in sec and milliseconds since start
#
# global  integer  $CW_timer_start  start time in sec
#
# no parameter is required
function cw.timer(){
        local timer_end; timer_end=$( date +%s.%N ) 
        local totaltime; totaltime=$( awk "BEGIN {print $timer_end - $CW_timer_start }" )

        local sec_time; sec_time=$( echo $totaltime | cut -f 1 -d "." )
        test -z "$sec_time" && sec_time=0 
        
        local ms_time; ms_time=$( echo $totaltime | cut -f 2 -d "." | cut -c 1-3 )
        
        echo "$sec_time.$ms_time sec"
} 

# Quit script with showing the total exitcode.
#
# global  integer  $rcAll  sum of retuncodes of all commands
#
# no parameter is required
function cw.quit(){
        local _color

        _color=error
        test $rcAll = 0 && _color=ok 

        echo; echo -n ">>>>> END $( cw.timer ) >>>>> "
        cw.cecho $_color "Terminating with exitcode [$rcAll] ($_color)"
        echo
        exit $rcAll
}

# ----- coloring -------------------------------------------------------

# Set a terminal color by a keyword
# Example:
#   cw.color cmd
#   ls -l 
#   color reset
#
# global  integer  $NO_COLOR  value 1 means: no color please; see http://no-color.org/
#
# param   string  keyword to set a color; one of reset | head|cmd|input | ok|warning|error
function cw.color(){
        local _color; _color=$1
        local sColorcode=""
        if [ "$NO_COLOR" = "1" ]; then
                _color="reset"
        fi
        case $_color in
                "reset") sColorcode="0"
                        ;;
                "head")  sColorcode="33" # yellow
                        ;;
                "cmd")   sColorcode="94" # light blue
                        ;;
                "input") sColorcode="92" # green
                        ;;
                "ok") sColorcode="92" # green
                        ;;
                "warning") sColorcode="33" # yellow
                        ;;
                "error") sColorcode="91" # red
                        ;;
                *) echo "ERROR: unknown color keyword: $_color"; return 1
        esac
        if [ -n "${sColorcode}" ]; then
                echo -ne "\e[${sColorcode}m"
        fi    
}

# Colored echo output using color and reset color afterwards
# see also: cw.color
#
# Example:
#   cw.cecho ok "Action was successful."
#
# param   string  color code ... see cw.color
# param   string  text to display
function cw.cecho (){
        local _color=$1; shift 1
        cw.color "$_color"; echo -n "$*"; cw.color reset; echo
}

# Print a headline for a help section
# param   string  emoji
# param   string  headline text
function cw.helpsection(){
        local _emoji; _emoji="$( cw.emoji "$1" '* ')"
        local _label="$2"
        echo
        cw.cecho head "####| ${_emoji}${_label} |####"
}

# ----- locking --------------------------------------------------------

# Helper function: generate a filename for locking
function cw._getlockfilename(){
        echo "/tmp/_lock__${*//[^a-zA-Z0-9]/_}"
}

# Verify locking and create one if no active lock was found
# see also: cw.lockstatus, cw.unlock
#
# global  string  $CW_lockfile  filename of the lockfile
#
# param   string  optional: string to create sonething uniq if your script can 
#                be started with multiple parameters
function cw.lock(){

        if [ -f "${CW_lockfile}" ]; then

                echo -n "[${FUNCNAME[0]}] "
                local _cw_lockpid
                _cw_lockpid=$( cut -f 2 -d " " "${CW_lockfile}" | grep "[0-9]")
                if [ -z "$_cw_lockpid" ]; then
                        cw.cecho error "ERROR: process pid was not fetched from lock file. Check the transfer processes manually, please."
                        exit 1
                fi

                # _cw_regex is "^" + username + spaces + found pid + single space
                local _cw_regex
                _cw_regex="^$( id -a | cut -f 1 -d ')' | cut -f 2 -d '(' )\ *$_cw_lockpid\ "

                if ps -ef | grep "$_cw_regex" >/dev/null
                then
                        cw.cecho error "ERROR: The process pid $_cw_lockpid seems to be still active. Aborting."
                        ps -ef | grep "$_cw_regex"
                        exit 1
                fi
                cw.cecho warning "INFO: Lock file $CW_lockfile was found but process $_cw_lockpid is not active anymore."
                cw.color reset
        fi

        echo -n "[${FUNCNAME[0]}] "
        if echo "Process $$ - $(date) start lock for $0: $*" > "${CW_lockfile}"
        then
                cw.cecho ok "OK"
        else
                cw.cecho error "ABORT - unable to create transfer lock"
                exit 2
        fi
}

# Check status of locking
# exit code is 0 if locking is active
# see also: cw.lock, cw.unlock
#
# Example: if cw.lockstatus; then echo Lock is ACTIVE; else echo NO LOCKING; fi
#
# global  string  CW_lockfile  filename for locking
function cw.lockstatus(){
        [ -n "${CW_lockfile}" ] && [ -f "${CW_lockfile}" ]
}

# Remove an existing locking
# no parameter is required
# see also: cw.lock, cw.lockstatus
#
# global  string  CW_lockfile  filename for locking
function cw.unlock(){
        echo -n "[${FUNCNAME[0]}] "
        if cw.lockstatus
        then                
                if rm -f "$CW_lockfile"
                then
                        cw.cecho ok "OK"
                else
                        cw.cecho error "ERROR: lock file ${CW_lockfile} was not removed"
                fi
        else
                cw.cecho warning "SKIP: no lock was found"
        fi
}

# ----------------------------------------------------------------------

# INIT:
CW_timer_start=$( date +%s.%N )
CW_lockfile=$( cw._getlockfilename "$0 $*" )

# ----------------------------------------------------------------------
