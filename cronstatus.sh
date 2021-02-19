#!/bin/bash


LOGDIR=/var/tmp/cronlogs
outfile=/tmp/cronjob_status.$$.tmp
outfile=/tmp/cronjob_status.tmp

typeset -i iMaxAge=`date +%s`
typeset -i iErrJobs=0


# ----------------------------------------------------------------------
# FUNCTIONS
# ----------------------------------------------------------------------

# get a value from logfile (everything behind "="
# param: label
# global: $logfile
function getLogValue(){
        grep "^$1=" $logfile | cut -f 2- -d "="
}



# ----------------------------------------------------------------------
# MAIN
# ----------------------------------------------------------------------

ls -1t $LOGDIR/*log | fgrep -v "/__" | while read logfile
do
        typeset -i iErr=0

        server=`basename $logfile | cut -f 1 -d "_"`
        jobname=`basename $logfile | cut -f 2 -d "_" | sed "s#\.log##"`


        sPre="    "
        sCmd=`getLogValue SCRIPTNAME`
        sLastStart=`getLogValue SCRIPTSTARTTIME`
        typeset -i iJobExpire=`getLogValue JOBEXPIRE`
        typeset -i rc=`getLogValue 'SCRIPTRC' | head -1`
        typeset -i iEcectime=`getLogValue 'SCRIPTEXECTIME' | head -1 | cut -f 1 -d " "`
        sTTL=`getLogValue 'SCRIPTTTL'`

        # ----- check return code
        statusRc='OK'
        if [ $rc -ne 0 ]; then
                iErr=$iErr+1
                statusRc='ERROR'
        fi

        # ----- check ttl value
        typeset -i iTTL=$sTTL
        typeset -i iTTLsec=0
        iTTL=$iTTL
        iTTLsec=$iTTL*60
        ttlstatus="OK"
        if [ -z $sTTL ]; then
                iErr=$iErr+1
                statusTtl="ERROR: ttl value is empty"
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
                if [ $iTTLsec -lt $iEcectime ]; then
                        iErr=$iErr+1
                        statusTtl="ERROR: $iTTL min = $iTTLsec s - is too low; exec time is $iEcectime s - set a higher TTL for this cronjob"
                        iErr=$iErr+1
                else
                        statusTtl="$statusTtl OK"
                fi
        fi
        # ----- check expire
        statusExpire="`date -d @$iJobExpire '+%Y-%m-%d %H:%M:%S'`"
        if [ $iJobExpire -lt $iMaxAge ]; then
                statusExpire="${statusExpire} ERROR"
                iErr=$iErr+1
        else
                statusExpire="${statusExpire} OK"
        fi

        # ----- OUTPUT
        echo
        echo --- $logfile

        echo "${sPre}${sCmd}"
        echo "${sPre}last start: ${sLastStart}"
        echo "${sPre}returncode: ${rc} ${statusRc}"
        echo "${sPre}duration: ${iEcectime} s"
        echo "${sPre}ttl: ${statusTtl}"
        echo "${sPre}expires: ${iJobExpire} ${statusExpire}"

        if [ $iErr -gt 0 ]; then
                echo "${sPre}CHECK FAILED"
                iErrJobs=$iErrJobs+1
        fi

done

echo
# TODO: $iErrJobs is in a while loop ... what is a subshell
# echo TOTALSTATUS: $iErrJobs cronjobs have an error
