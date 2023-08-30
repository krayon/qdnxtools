#!/bin/bash
# vim:set ts=4 sw=4 tw=80 et ai si cindent cino=L0,b1,(1s,U1,m1,j1,J1,)50,*90 cinkeys=0{,0},0),0],\:,0#,!^F,o,O,e,0=break:
#
#/**********************************************************************
#    WaitForPID
#    Copyright (C)2015-2023 Krayon (Todd Harbour)
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


# Version
APP_NAME="WaitForPID"
APP_VER="0.13.0"
APP_COPY="(C)2015-2023 Krayon (Todd Harbour)"
APP_URL="https://github.com/krayon/qdnxtools"

# Program name
_binname="${_APP_NAME,,}"
_binname="${0##*/}"
_binnam_="${_binname//?/ }"

# exit condition constants
ERR_NONE=0
ERR_UNKNOWN=1
# START /usr/include/sysexits.h {
ERR_USAGE=64       # command line usage error
ERR_DATAERR=65     # data format error
ERR_NOINPUT=66     # cannot open input
ERR_NOUSER=67      # addressee unknown
ERR_NOHOST=68      # host name unknown
ERR_UNAVAILABLE=69 # service unavailable
ERR_SOFTWARE=70    # internal software error
ERR_OSERR=71       # system error (e.g., can't fork)
ERR_OSFILE=72      # critical OS file missing
ERR_CANTCREAT=73   # can't create (user) output file
ERR_IOERR=74       # input/output error
ERR_TEMPFAIL=75    # temp failure; user is invited to retry
ERR_PROTOCOL=76    # remote error in protocol
ERR_NOPERM=77      # permission denied
ERR_CONFIG=78      # configuration error
# END   /usr/include/sysexits.h }
ERR_MISSINGDEP=90



wait_retry=10



show_version() {
    echo -e "\n\
${APP_NAME} v${APP_VER}\n\
${APP_COPY}\n\
${APP_URL}${APP_URL:+\n}\
"
} # show_version()

show_usage() {
    show_version

cat <<EOF

${APP_NAME} converts text to Slack emoji

Usage: ${_binname} [-v|--verbose] -h|--help
       ${_binname} [-v|--verbose] -V|--version

       ${_binname} [-v|--verbose] [-a|--any] <PID> [<PID> [...]]

       ${_binname} [-v|--verbose] [-a|--any] <<<"<PID> <PID>"
       ${_binname} [-v|--verbose] [-a|--any] < <(<CMD_GENS_PID_LIST>)
       etc


  -h|--help           - Displays this help
  -V|--version        - Displays the program version
  -v|--verbose        - Displays extra debugging information.  This is the same
                        as setting DEBUG=1 in your config.
  -a|--any            - If this option is specified, waits for ANY PID supplied.
                        By default (when not specified) ${APP_NAME} will wait
                        for ALL PIDs supplied.
  <PID>               - A PID to wait for. Multiple can be specified. If no PIDs
                        are specified, or if the only PID is '-', PIDs will
                        instead be read from stdin.



Example: ${_binname} <<<"1234 555"
         ${_binname} 1234 555
         ${_binname} < <(echo "1234"; echo "555")
EOF

} # show_usage()

# Debug echo
decho() {
    # global $DEBUG
    local line

    # Not debugging, get out of here then
    [ -z "${DEBUG}" ] || [ "${DEBUG}" -le 0 ] && return

    # If message is "-" or isn't specified, use stdin ("" is valid input)
    msg="${@}"
    [ ${#} -lt 1 ] || [ "${msg}" == "-" ] && msg="$(</dev/stdin)"

    while IFS="" read -r line; do #{
        >&2 echo "[$(date +'%Y-%m-%d %H:%M')] DEBUG: ${line}"
    done< <(echo "${msg}") #}
} # decho()

#function==============================================================
# isint v0.8
#======================================================================
# Returns if the string(s) provided is an integer or not
#----------------------------------------------------------------------
# isint <STRING> [<STRING> [...]]
#----------------------------------------------------------------------
# Outputs:
#   NOTHING
# Returns:
#   0 = SUCCESS: Provided string(s) is an integer
#   1 = (PARTIAL) FAILURE: NOT an integer
#       (or no <STRING> provided)
#----------------------------------------------------------------------
isint() {
    [ $# -lt 1 ] && return 1

    local ret=0
    while [ $# -gt 0 ]; do #{
        local num="${1}"
        # Ensure param is an integer
        # shellcheck disable=SC2003 # expr returns error here which we want
        expr "${num}" + 1 &>/dev/null || {
            # Invalid integer
            >&2 echo "WARNING: Invalid integer: ${num}"
            ret=1
            shift 1
            continue
        }

        shift 1
    done #}

    return ${ret}
} # isint()

# Returns the number of this PID running (0 or 1)
pidrunning() {
    # Doesn't work on N900:
    #echo $(ps -eo pid|sed '/PID/d'|grep -w "${1}"|wc -l)
    #OLD: echo $(ps -e|awk '{print $1}'|grep "\<${1}\>"|wc -l)
    ps -p "${1}" >/dev/null 2>&1
}



# START #

# Clear DEBUG if it's 0
[ -n "${DEBUG}" ] && [ "${DEBUG}" == "0" ] && DEBUG=

ret=${ERR_NONE}

# If debug file, redirect stderr out to it
[ -n "${ERROR_LOG}" ] && exec 2>>"${ERROR_LOG}"



#----------------------------------------------------------

# Process command line parameters
opts=$(\
    getopt\
        --options v,h,V,a \
        --long verbose,help,version,any \
        --name "${_binname}"\
        --\
        "$@"\
) || {
    >&2 echo "ERROR: Syntax error"
    >&2 show_usage
    exit ${ERR_USAGE}
}

eval set -- "${opts}"
unset opts

anypid=0
stdin=0
while :; do #{
    case "${1}" in #{
        # Verbose mode # [-v|--verbose]
        -v|--verbose)
            decho "Verbose mode specified"
            DEBUG=1
        ;;

        # Help # -h|--help
        -h|--help)
            decho "Help"

            show_usage
            exit ${ERR_NONE}
        ;;

        # Version # -V|--version
        -V|--version)
            decho "Version"

            show_version
            exit ${ERR_NONE}
        ;;

        # Any # -a|--any
        -a|--any)
            decho "Any PID"

            anypid=1
        ;;

        --)
            shift
            break
        ;;

        # Read stdin
        -)
            decho "Read PIDs from stdin"

            stdin=1
        ;;

        *)
            >&2 echo "ERROR: Unrecognised parameter ${1}..."
            exit ${ERR_USAGE}
        ;;
    esac #}

    shift

done #}

# Check for non-optional parameters
#-

# TODO: Are you NOT supporting non-specific parameters?
## Unrecognised parameters
#[ ${#} -gt 0 ] && {
#    >&2 echo "ERROR: Too many parameters: ${@}..."
#    exit ${ERR_USAGE}
#}



# No parameters, try stdin
[ ${#} -eq 0 ] && stdin=1

decho "START"



retval=${ERR_NONE}

pids=()
forkedpids=()
pidcount=0
while [ "${#}" -gt 0 ]; do #{
    param="${1}"; shift 1

    decho "Processing parameter: ${param}"

    [ "${param}" == '-' ] && stdin=1 && continue

    if [ -z "${param}" ] || ! isint "${param}"; then #{
        >&2 echo "ERROR: PID must be a number: ${param}"
        show_usage
        exit ${ERR_USAGE}
    fi #}

    pids[${pidcount}]=${param}
    pidcount=$((pidcount + 1))
done #}

if [ ${stdin} -gt 0 ]; then #{
    decho "Reading stdin..."
    while read -r line; do #{
        decho "Processing line: ${line}"
        while [ ! -z "${line}" ]; do #{
            read -r param line <<<"${line}"
            decho "Processing parameter: ${param}"

            isint "${param}" || {
                >&2 echo "ERROR: PID must be a number: ${param}"
                show_usage
                exit ${ERR_USAGE}
            }

            pids[${pidcount}]=${param}
            pidcount=$((pidcount + 1))
        done #}
    done #}
fi #}

decho "${pidcount} PIDs: ${pids[@]}"

pidsleft=${pidcount}
[ ${anypid} -gt 0 ] && pidsleft=1 
while [ ${pidsleft} -gt 0 ]; do #{
    decho "PIDs left to wait for: ${pidsleft}"

    for i in $(seq 0 $((pidcount - 1))); do #{
        p="${pids[${i}]}"

        [ ${p} -eq 0 ] && continue

        pidrunning "${p}" || {
            decho "PID finished: ${p}"

            pids[${i}]=0
            pidsleft=$((pidsleft - 1))
        }

        [ ${pidsleft} -lt 1 ] && break
    done #}

    [ ${pidsleft} -gt 0 ] && sleep ${wait_retry}
done #}

exit ${ERR_NONE}
