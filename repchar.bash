#!/bin/bash

PROG="${0##*/}"

[ "${1}" == "--help" ] || [ "${1}" == "-h" ] && {

cat <<EOF
Repeats a given character (or string) a specified number of times.

Usage: ${PROG} -h|--help
       ${PROG} <char> <count>

-h|--help           - Displays this help
<char>              - Character (or string) to repeat.
<count>             - Number of times to repeat <char>.

Example: = 10
=========
EOF

    exit 0
}

[ ${#} -ne 2 ] && echo >&2 "ERROR: Invalid number of parameters" && exit 1

i=1
while [ ${i} -lt ${2} ]; do #{
    echo -n "${1}"
    i=$((${i} + 1))
done #}
echo

# vim:ts=4:sw=4:et:ai:si