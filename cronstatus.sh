#!/bin/bash
# ------------------------------------------------------------
#
# CRONWRAPPER :: STATUS
#
# Show status for all cronjobs using the cronwrapper
#
# ------------------------------------------------------------
# 2022-01-12  ahahn  1.1  fixes based on shellcheck
# 2022-03-09  ahahn  1.2  added cw.* functions
# 2022-09-21  ahahn  1.3  added colored OK or ERROR texts
# 2022-09-22  ahahn  1.4  add last output lines; add total status; exitstatus > 0 on error 
# ------------------------------------------------------------

_version=1.4

LOGDIR=/var/tmp/cronlogs
# outfile=/tmp/cronjob_status.$$.tmp
# outfile=/tmp/cronjob_status.tmp

test -f $( dirname $0)/cronwrapper.cfg && . $( dirname $0)/cronwrapper.cfg
. $( dirname $0)/inc_cronfunctions.sh

typeset -i iMaxAge
iMaxAge=$(date +%s)
typeset -i iErrJobs=0

statusOK=$(cw.color ok ; echo -n "OK"; cw.color reset)
statusERROR=$(cw.color error ; echo -n "ERROR"; cw.color reset)

# ----------------------------------------------------------------------
# FUNCTIONS
# ----------------------------------------------------------------------

# get a value from logfile (everything behind "="
# param: label
# global: $logfile
function getLogValue(){
        grep "^$1=" "$logfile" | cut -f 2- -d "="
}

# get logfiles of all cronwrapper cronjobs
function getLogfiles(){
        ls -1t "$LOGDIR"/*log | grep -Fv "/__"        
}


# ----------------------------------------------------------------------
# MAIN
# ----------------------------------------------------------------------

cat <<ENDOFHEAD
____________________________________________________________________________________

CRONJOBS on [$( hostname -f )]
________________________________________________________________________________v$_version
ENDOFHEAD

for logfile in $( getLogfiles )
do
        typeset -i iErr=0

        # server=$(basename "$logfile" | cut -f 1 -d "_")
        # jobname=$(basename "$logfile" | cut -f 2 -d "_" | sed "s#\.log##")

        sPre="    "
        sCmd=$(getLogValue SCRIPTNAME)
        sLastStart=$(getLogValue SCRIPTSTARTTIME)
        typeset -i iJobExpire
        iJobExpire=$(getLogValue JOBEXPIRE)
        typeset -i rc
        rc=$(getLogValue 'SCRIPTRC' | head -1)
        typeset -i iExectime
        iExectime=$(getLogValue 'SCRIPTEXECTIME' | head -1 | cut -f 1 -d " ")
        sTTL=$(getLogValue 'SCRIPTTTL')

        # ----- check return code
        statusRc="${statusOK}"
        if [ $rc -ne 0 ]; then
                iErr+=1
                statusRc="${statusERROR}"
        fi

        # ----- check ttl value
        typeset -i iTTL=$sTTL
        typeset -i iTTLsec=0
        
        iTTLsec=$(( iTTL*60 ))
        # ttlstatus="OK"
        if [ -z "$sTTL" ]; then
                iErr+=1
                statusTtl="${statusERROR}: ttl value is empty"
        else
                # human readable ttl in min/ hours/ days
                statusTtl="$iTTL min"
                if [ $iTTL -gt 60 ]; then
                        iTTL=$iTTL/60;
                        statusTtl="$sTTL - $iTTL h"
                        if [ $iTTL -gt 24 ]; then
                                iTTL=$iTTL/24;
                                statusTtl="$sTTL - $iTTL d"
                        fi
                fi
                if [ $iTTLsec -lt $iExectime ]; then
                        iErr=$iErr+1
                        statusTtl="${statusERROR}: $iTTL min = $iTTLsec s - is too low; exec time is $iExectime s - set a higher TTL for this cronjob"
                        iErr+=1
                else
                        statusTtl="$statusTtl ${statusOK}"
                fi
        fi
        # ----- check expire
        statusExpire="$(date -d @$iJobExpire '+%Y-%m-%d %H:%M:%S')"
        if [ $iJobExpire -lt $iMaxAge ]; then
                statusExpire="${statusExpire} ${statusERROR}"
                iErr+=1
        else
                statusExpire="${statusExpire} ${statusOK}"
        fi

        # ----- OUTPUT
        echo
        cw.cecho "head" "--- $logfile"

        echo "${sPre}command   : ${sCmd}"
        echo "${sPre}last start: ${sLastStart}"
        echo "${sPre}returncode: ${rc} ${statusRc}"
        if [ $rc -ne 0 ]; then
                echo
                echo "${sPre}${sPre}Last lines in output:"
                getLogValue SCRIPTOUT | tail -20 | sed "s#^#${sPre}${sPre}#g"
                echo
        fi
        echo "${sPre}duration  : ${iExectime} s"
        echo "${sPre}ttl       : ${statusTtl}"
        echo "${sPre}expires   : ${iJobExpire} ${statusExpire}"

        if [ $iErr -gt 0 ]; then
                cw.cecho "error" "${sPre}CHECK FAILED"
                iErrJobs=$iErrJobs+1
        else
                cw.cecho "ok" "${sPre}CHECK OK"
        fi
done

echo "____________________________________________________________________________________"

echo "JOBS: $(getLogfiles | wc -l ) .. ERRORS: $iErrJobs"
echo
exit $iErrJobs