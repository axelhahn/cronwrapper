# Handling der Returncodes
typeset -i rc=0
typeset -i rcAll=0

function fetchRc(){
        rc=$?
        echo "rc=$rc"
        rcAll=$rcAll+$rc
}

# ein Kommando ausfuehren und returncode ausgeben und auf rcAll aufsummieren
function exec2() {

        set -vx
        $*
        rc=$?
        set +vx
        rcAll=$rcAll+$rc
}


# vom Remoteserver eine Liste von Verzeichnissen holen
# Params: Server  Zielverzeichnis lokal  Liste der Verzeichnisse (remote)
function getRemoteFiles(){

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

function quit(){
        echo
        echo "beende mit Returncode $rcAll"
        exit $rcAll
}
