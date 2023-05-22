#!/bin/bash
# ----------------------------------------------------------------------
#
# CRONWRAPPER :: STATUS
#
# Show status for all cronjobs using the cronwrapper
#
# ----------------------------------------------------------------------
# 2022-01-12  ahahn  1.1  fixes based on shellcheck
# 2022-03-09  ahahn  1.2  added cw.* functions
# 2022-09-21  ahahn  1.3  added colored OK or ERROR texts
# 2022-09-22  ahahn  1.4  add last output lines; add total status; exitstatus > 0 on error 
# 2022-10-27  ahahn  1.5  add 2 checks for hostname: is it a fqdn + filename matches hostname -f
# 2023-05-22  ahahn  1.6  show running jobs
# ----------------------------------------------------------------------

_version=1.6

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
sPre="    "

# ----------------------------------------------------------------------
# FUNCTIONS
# ----------------------------------------------------------------------

# get a value from logfile (everything behind "=")
# param: label
# global: $logfile
function getLogValue(){
        grep "^$1=" "$logfile" | cut -f 2- -d "="
}

# get logfiles of all cronwrapper cronjobs
function getLogfiles(){
        ls -1t "$LOGDIR"/*log | grep -Fv "/__"
}

# get logfiles of all cronwrapper cronjobs
function getRunningfiles(){
        ls -1t "$LOGDIR"/*log.running 2>/dev/null
}

# ----------------------------------------------------------------------
# MAIN
# ----------------------------------------------------------------------

sCurrentServer=$(hostname -f)
cat <<ENDOFHEAD
____________________________________________________________________________________

CRONJOBS on [$( hostname -f )]
______________________________________________________________________________/ v$_version
ENDOFHEAD


# ---------- Show logs

for logfile in $( getLogfiles )
do
        typeset -i iErr=0

        # server=$(basename "$logfile" | cut -f 1 -d "_")
        # jobname=$(basename "$logfile" | cut -f 2 -d "_" | sed "s#\.log##")

        sCmd=$(getLogValue SCRIPTNAME)
        sLastStart=$(getLogValue SCRIPTSTARTTIME)
        typeset -i iJobExpire
        iJobExpire=$(getLogValue JOBEXPIRE)
        typeset -i rc
        rc=$(getLogValue 'SCRIPTRC' | head -1)
        typeset -i iExectime
        iExectime=$(getLogValue 'SCRIPTEXECTIME' | head -1 | cut -f 1 -d " ")
        # remark: other execution times of the same job
        # grep "=JOBNAME:" /var/tmp/cronlogs/*joblog*

        sTTL=$(getLogValue 'SCRIPTTTL')

        # ----- check return code
        sServer=$(basename "$logfile" | cut -f 1 -d "_")
        sFqdnCheck=
        sServerCheck=

        if test "$REQUIREFQDN" != "0" && ! echo "$sServer" | grep "\." >/dev/null; then
                sFqdnCheck="WARNING   : No FQDN in filename - only the short hostname: [$sServer]"
                iErr+=1
        fi
        if test "${sCurrentServer}" != "$sServer"; then
                sServerCheck="WARNING   : hostname -f returns [${sCurrentServer}] ... and differs to [$sServer] from logfile."
                iErr+=1
        fi

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
        test -n "${sFqdnCheck}"   && cw.cecho "warning" "${sPre}${sFqdnCheck}"
        test -n "${sServerCheck}" && cw.cecho "warning" "${sPre}${sServerCheck}"


        if [ $iErr -gt 0 ]; then
                cw.cecho "error" "${sPre}CHECK FAILED"
                iErrJobs=$iErrJobs+1
        else
                cw.cecho "ok" "${sPre}CHECK OK"
        fi
done

# ---------- Show running jobs

if getRunningfiles >/dev/null 2>&1 ; then
        echo "____________________________________________________________________________________"
        echo
        echo "CURRENTLY RUNNING JOBS:"

        for logfile in $( getRunningfiles )
        do
                sCmd=$(getLogValue SCRIPTNAME)
                sLastStart=$(getLogValue SCRIPTSTARTTIME)
                typeset -i iSince=($( date '+%s' )-$( echo "$sLastStart" | cut -f 2 -d ',' ))/60
                typeset -i iTTL=$(getLogValue 'SCRIPTTTL')
                if [ $iTTL -lt $iSince ]; then
                        statusTtl="${statusERROR}: TTL=$iTTL min is lower than execution time of ${iSince} min"
                        iErr+=1
                fi

                echo
                cw.cecho "head" "${sPre}--- for $iSince min - $logfile"
                echo "${sPre}${sPre}command   : ${sCmd}"
                echo "${sPre}${sPre}last start: ${sLastStart}"
                echo "${sPre}${sPre}ttl       : ${iTTL}"

        done
else
        echo
        echo "There is no running job."
fi

echo "____________________________________________________________________________________"
echo "JOBS: $(getLogfiles | wc -l ) .. ERRORS: $iErrJobs"
echo
exit $iErrJobs

# ----------------------------------------------------------------------
