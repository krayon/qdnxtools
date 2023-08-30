#!/bin/bash
# vim:ts=4:tw=80:sw=4:expandtab

# WaitForPID
#
# Waits for a PID

wait_retry=30

bin="$(basename "${0}")"
proper_name="WaitForPID"
ver=0.1

# Show Help
function showhelp {
    echo -e "\
${proper_name} v${ver}\n\
\n\
Waits for a PID.\n\
\n\
Usage: ${bin} -h|--help\n\
Usage: ${bin} <PID>\n\
\n\
-h|--help           - Display (this) help\n\
<PID>               - PID to wait for.\n\
\n\
Example: ${bin} 1234\n\
    "
}

# Checks for number (returns the number if true, NULL otherwise)
function isanum {
    echo "$(echo "${1}"|sed '/[^[:digit:]]/d')"
}

# Returns the number of this PID running (0 or 1)
function pidrunning {
    echo $(ps -eo pid|sed '/PID/d'|grep -w "${1}"|wc -l)
}

retval=0

if [ "${1}" == "-h" ] || [ "${1}" == "--help" ]; then
    # Show the help
    showhelp
    exit 0
fi

if [ -z "${1}" ] || [ -z "$(isanum "${1}")" ]; then
    echo "ERROR: PID must be a number" >&2
    showhelp
    exit 1
fi

pid=${1}

while [ $(pidrunning ${pid}) -ne 0 ]; do
    sleep ${wait_retry}
done
exit 0
