#!/bin/bash
# vim:ts=4:tw=80:sw=4:expandtab

# WaitForPID
#
# Waits for a PID

wait_retry=30

bin="$(basename "${0}")"
proper_name="WaitForPID"
ver=0.12

# Show Help
function showhelp {
    echo -e "\
${proper_name} v${ver}\n\
\n\
Waits for a PID.\n\
\n\
Usage: ${bin} -h|--help\n\
Usage: ${bin} <PID> [<PID> [...]]\n\
\n\
-h|--help           - Display (this) help\n\
<PID>               - PID(s) to wait for.\n\
\n\
Example: ${bin} 1234 555\n\
    "
}

# Checks for number (returns the number if true, NULL otherwise)
function isanum {
    [ "${1}" -eq "${1}" 2>/dev/null ] && echo ${1}
}

# Returns the number of this PID running (0 or 1)
function pidrunning {
    # Doesn't work on N900:
    #echo $(ps -eo pid|sed '/PID/d'|grep -w "${1}"|wc -l)
    #OLD: echo $(ps -e|awk '{print $1}'|grep "\<${1}\>"|wc -l)
    ps -p "${1}" >/dev/null 2>&1
}

retval=0

pids=()
forkedpids=()
pidcount=0
while [ "${#}" -gt 0 ]; do
    if [ "${1}" == "-h" ] || [ "${1}" == "--help" ]; then
        # Show the help
        showhelp
        exit 0
    elif [ -z "${1}" ] || [ -z "$(isanum "${1}")" ]; then
        echo "ERROR: PID must be a number" >&2
        showhelp
        exit 1
    fi

    pids[${pidcount}]=${1}
    pidcount=$((${pidcount} + 1))
    shift 1
done

if [ ${pidcount} -lt 1 ]; then
    showhelp
    exit 1
elif [ ${pidcount} -gt 1 ]; then
    for pidid in $(seq 0 $((${pidcount} - 1))); do
        ${0} ${pids[${pidid}]} & forkedpids[${pidid}]=$!
    done

    wait

    exit 0
else
    pid=${pids[0]}
fi

while pidrunning ${pid}; do
    sleep ${wait_retry}
done
exit 0
