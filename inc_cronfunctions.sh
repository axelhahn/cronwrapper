# ======================================================================
# 
# INCLUDE file with shared functions
#
# source the script and call cw.help
# 
# ----------------------------------------------------------------------
# 2022-03-09  ahahn  added cw.* functions; others marked as deprecated
# ======================================================================

# Handling of exitocdes
typeset -i rc=0     # the last detected exitcode of a command
typeset -i rcAll=0  # sum of all collected exitcodes

# set a start time
export CW_timer_start
export CW_lockfile

# ----------------------------------------------------------------------
# deprecated functions witout "cw." prefix
# ----------------------------------------------------------------------

# draw a message for deprecated warning
# param  string  name of deprecated function
# param  string  text for replacement
function cw._isDeprecated(){
        local _fkt
        _fkt=$1
        shift 1
        cw.cecho warning "WARNING: function $_fkt() is DEPRECATED. Replace it with <$*>."
}

# DEPRECATED
# vom Remoteserver eine Liste von Verzeichnissen holen
# Params: Server  Zielverzeichnis lokal  Liste der Verzeichnisse (remote)
function getRemoteFiles(){

        cw._isDeprecated "${FUNCNAME[0]}" "a self written function"

        srvSource=$1
        targetDir=$2
        shift 2

        dirlist=$*

        echo "--- ${srvSource} - to $targetDir"
        mkdir -p "${targetDir}"

        for mydir in $dirlist
        do
                echo -n "${mydir} "
                rsync -a "${srvSource}:${mydir}" "${targetDir}"
                fetchRc
        done
        echo

}

# DEPRECATED
function color(){
        cw.color $*
        cw._isDeprecated "${FUNCNAME[0]}" "cw.color"
}

# DEPRECATED
function cecho(){
        cw.cecho $*
        cw._isDeprecated "${FUNCNAME[0]}" "cw.cecho"
}

# DEPRECATED
# ein Kommando ausfuehren und returncode ausgeben und auf rcAll aufsummieren
function exec2() {
        cw._isDeprecated "${FUNCNAME[0]}" "cw.exec"
        cw.exec $*
}

# DEPRECATED
# get last exitcode and store it in global var $rc
function fetchRc(){
        cw.fetchRc
        cw._isDeprecated "${FUNCNAME[0]}" "cw.fetchRc"
}

# DEPRECATED
function quit(){
        cw._isDeprecated "${FUNCNAME[0]}" "cw.quit"
        cw.quit $*
}

# ----------------------------------------------------------------------

# show help for available cw.* functions
# no parameter required
function cw.help(){
        local _self="${BASH_SOURCE[0]}"
        cw.cecho head "HELP FOR CRONWRAPPER FUNCTIONS"
        cw.cecho head "auto generated list of implemented cw.* functions"
        echo
        grep "^function\ cw\.[a-z][a-z]*" "$_self" | cut -f 2 -d " " | cut -f 1 -d '(' | sort | while read -r fktname
        do 
                cw.cecho cmd $fktname
                typeset -i local _linestart
                _linestart=$( grep -En "function\ $fktname\ *\(" "$_self" | cut -f 1 -d ':' )
                typeset -i local _print_start=$_linestart-5

                sed -n ${_print_start},${_linestart}p $_self | grep '^#' | grep -v "\-\-\-\-\-" | cut -c 3- | sed "s#^#    #g"
                echo
        done

}

# ----------------------------------------------------------------------

# get last exitcode and store it in global var $rc
# no parameter is required
function cw.fetchRc(){
        rc=$?
        local _color

        _color=error
        test $rc = 0 && _color=ok 
        
        echo -n "--> "
        cw.cecho $_color "rc=$rc ($_color)"
        rcAll+=$rc
}

# execute a given command, show return code (and add it to final exit code)
# param  string(s)  command line to execute 
function cw.exec() {
        echo $*
        cw.color cmd 
        $*
        cw.fetchRc

}

# get time in sec and milliseconds since start
# no parameter is required
function cw.timer(){
        local timer_end=$( date +%s.%N ) 
        local totaltime=$( awk "BEGIN {print $timer_end - $CW_timer_start }" )

        local sec_time=$( echo $totaltime | cut -f 1 -d "." )
        test -z "$sec_time" && sec_time=0 
        
        local ms_time=$( echo $totaltime | cut -f 2 -d "." | cut -c 1-3 )
        
        echo "$sec_time.$ms_time sec"
} 

# quit script with showing the total exitcode.
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

# ----------------------------------------------------------------------
# coloring
# ----------------------------------------------------------------------

# set a terminal color by a keyword
# param  string  keyword to set a color; one of reset | head|cmd|input | ok|warning|error
function cw.color(){
        local sColorcode=""
        case $1 in
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
        esac
        if [ -n "${sColorcode}" ]; then
                echo -ne "\e[${sColorcode}m"
        fi    
}

# colored echo output using color and reset color afterwards
# param  string  color code ... see cw.color
# param  string  text to display
function cw.cecho (){
        local _color=$1; shift 1
        cw.color "$_color"; echo -n "$*"; cw.color reset; echo
}

# ----------------------------------------------------------------------
# locking
# ----------------------------------------------------------------------

# helper function: generate a filename for locking
function cw._getlockfilename(){
        echo "/tmp/_lock__${*//[^a-zA-Z0-9]/_}"
}

# verify locking and create one if no active lock was found
# param  string  optional: string to create sonething uniq if your script can 
#                be started with multiple parameters
# see cw.lockstatus, cw.unlock
function cw.lock(){

        local _cw_label
        _cw_label=$( echo "$0 $*" | sed "s#[^a-zA-Z0-9]#_#g" )

        if [ -f "${CW_lockfile}" ]; then

                local _cw_lockpid
                _cw_lockpid=$( cut -f 2 -d " " "${CW_lockfile}" | grep "[0-9]")
                if [ -z "$_cw_lockpid" ]; then
                        cw.cecho error "ERROR: process pid was not fetched from lock file. Check the transfer processes manually, please."
                        exit 1
                fi

                if ps -ef | grep "$_cw_lockpid" | grep "$_cw_label"
                then
                        cw.cecho error "ERROR: The process pid $_cw_lockpid seems to be still active. Aborting."
                        exit 1
                fi
                cw.cecho warning "INFO: Lock file $CW_lockfile was found but process $_cw_lockpid is not active anymore."
                cw.color reset
        fi

        if ! echo "Process $$ - $(date) start lock for $0 $* ... $_cw_label" > "${CW_lockfile}"
        then
                cw.cecho error "ABORT - unable to create transfer lock"
                exit 2
        fi
}

# check status of locking
# exit code is 0 if locking is active
# Example: if cw.lockstatus; then echo Lock is ACTIVE; else echo NO LOCKING; fi
# see cw.lock, cw.unlock
function cw.lockstatus(){
        test -f "${CW_lockfile}"
}

# remove an existing locking
# no parameter is required
# see cw.lock, cw.lockstatus
function cw.unlock(){
        test -n "${CW_lockfile}"
        rm -f "$CW_lockfile" || cecho error "ERROR: lock file ${CW_lockfile} was not removed"
}

# ----------------------------------------------------------------------

# INIT:
CW_timer_start=$( date +%s.%N )
CW_lockfile=$( cw._getlockfilename "$0 $*" )

# ----------------------------------------------------------------------
