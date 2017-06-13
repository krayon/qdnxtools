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

# If first param is NULL, obviously the output will be nothing
[ -z "${1}" ] && exit 0

# Expecting 2 params
[ ${#} -ne 2 ] && {
    echo >&2 "ERROR: Invalid number of parameters"
    exit 1
}

# Second param must be a number
[ "${2}" -eq "${2}" ] &>/dev/null || {
    echo >&2 "ERROR: Invalid <num>: ${2}"
    exit 1
}

printf "${1}%.0s" $(eval echo "{1..${2}}")
echo

# vim:ts=4:sw=4:et:ai:si