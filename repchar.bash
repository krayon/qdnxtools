#!/bin/bash
# vim:set ts=4 sw=4 tw=80 et ai si:
# ( settings from: http://datapax.com.au/code_conventions/ )
#
#/**********************************************************************
#    Rep(eat) Char(acter)
#    Copyright (C) 2013-2017 Todd Harbour
#
#    This program is free software; you can redistribute it and/or
#    modify it under the terms of the GNU General Public License
#    version 2 ONLY, as published by the Free Software Foundation.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program, in the file COPYING or COPYING.txt; if
#    not, see http://www.gnu.org/licenses/ , or write to:
#      The Free Software Foundation, Inc.,
#      51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
# **********************************************************************/

# repchar
#--------
# Repeats a character or series of characters. Can be sourced or run.



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

    # Raw that number (strip of extras)
    num=$((${2} + 0))

    # If second param is a zero, obviously the output will be nothing
    [ "${num}" -eq 0 ] && echo && return 0

    printf "%.0s${1}" $(eval echo "{1..${num}}")
    echo
} # repchar



# We are being sourced
[ "${0}" != "${BASH_SOURCE}" ] && return 0

# We are being run as a script
repchar "${@}"; exit $?

