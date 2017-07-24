#!/bin/bash

# We are being run as a script, so set it's name
[ "${0}" == "${BASH_SOURCE}" ] && _repcharbinname="${0##*/}"

# repchar -h|--help
# repchar <char> <count>
function repchar() {

    [ "${1}" == "--help" ] || [ "${1}" == "-h" ] && {

cat <<EOF
Repeats a given character (or string) a specified number of times.

Can be run directly or sourced ( . "${_repcharbinname:-repchar}" ).

Usage: ${_repcharbinname:-repchar} -h|--help
       ${_repcharbinname:-repchar} <char> <count>

-h|--help           - Displays this help
<char>              - Character (or string) to repeat.
<count>             - Number of times to repeat <char>.

Example: ${_repcharbinname:-repchar} = 10
=========
EOF

        return 0
    }

    # Expecting 2 params
    [ ${#} -ne 2 ] && {
        echo >&2 "ERROR: Invalid number of parameters"
        return 1
    }

    # If first param is NULL, obviously the output will be nothing
    [ -z "${1}" ] && echo && return 0

    # Second param must be a number
    [ "${2}" -eq "${2}" ] &>/dev/null || {
        echo >&2 "ERROR: Invalid <num>: ${2}"
        return 1
    }

    # If second param is a zero, obviously the output will be nothing
    [ "${2}" -eq 0 ] && echo && return 0

    printf "%.0s${1}" $(eval echo "{1..${2}}")
    echo
} # repchar

# We are being sourced
[ "${0}" != "${BASH_SOURCE}" ] && return 0

# We are being run as a script
repchar "${@}"; exit $?

# vim:ts=4:sw=4:tw=80:et:ai:si
