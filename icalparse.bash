#!/bin/bash
# vim:set ts=4 sw=4 tw=80 et ai si:
# ( settings from: http://datapax.com.au/code_conventions/ )
#
#/**********************************************************************
#    iCalParse
#    Copyright (C) 2016-2018 Todd Harbour
#
#    This program is free software; you can redistribute it and/or
#    modify it under the terms of the GNU General Public License
#    version 3 ONLY, as published by the Free Software Foundation.
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

# icalparse
# ---------
# Simple viewer for iCal files

# Config paths
_ETC_CONF="/etc/icalparse.conf"
_HOME_CONF="${HOME}/.icalparserc"



# [ CONFIG_START

# iCal Parse Default Configuration
# ================================

# DEBUG
#   This defines debug mode which will output verbose info to stderr
#   or, if configured, the debug file ( ERROR_LOG ).
DEBUG=0

# ERROR_LOG
#   The file to output errors and debug statements (when DEBUG != 0) instead of
#   stderr.
#ERROR_LOG="/tmp/icalparse.log"

# ] CONFIG_END

###
# Config loading
###
[ ! -z "${_ETC_CONF}"  ] && [ -r "${_ETC_CONF}"  ] && . "${_ETC_CONF}"
[ ! -z "${_HOME_CONF}" ] && [ -r "${_HOME_CONF}" ] && . "${_HOME_CONF}"

# Version
APP_NAME="iCal Parse (icalparse)"
APP_VER="0.01"
#TODO:
#APP_URL="http://www.datapax.com.au/icalparse/"

# Program name
PROG="$(basename "${0}")"

# exit condition constants
ERR_NONE=0
ERR_MISSINGDEP=1
ERR_UNKNOWNOPT=2
ERR_INVALIDOPT=3
ERR_MISSINGPARAM=4

# Defaults not in config
files=()



# Params:
#   NONE
function show_version() {
    echo -e "\
${APP_NAME} v${APP_VER}\n\
${APP_URL}\n\
"
}

# Params:
#   NONE
function show_usage() {
    show_version

cat <<EOF

${APP_NAME} parses an iCal file, displaying a summary.

Usage: ${PROG} -h|--help
       ${PROG} -V|--version
       ${PROG} [-v|--verbose] <file>

-h|--help           - Displays this help
-V|--version        - Displays the program version
-v|--verbose        - Displays extra debugging information.  This is the same
                      as setting DEBUG=1 in your config.
<file>              - The calendar file to parse.

Example: ${PROG} appointment.ics
EOF

}

# Params:
#   $1 =  (s) command to look for
#   $2 = [(s) suspected package name]
function check_for_cmd() {
    # Check for ${1} command
    cmd="UNKNOWN"
    [ $# -gt 0 ] && cmd="${1}" && shift 1
    pkg="${cmd}"
    [ $# -gt 0 ] && pkg="${1}" && shift 1

    which "${cmd}" >/dev/null 2>&1 || {
cat >&2 <<EOF
ERROR: Cannot find ${cmd}.  This is required.
Ensure you have ${pkg} installed or search for ${cmd}
in your distribution's packages.
EOF

        exit ${ERR_MISSINGDEP}
    }

    return ${ERR_NONE}
}

# Debug echo
function decho() {
    # Not debugging, get out of here then
    [ ${DEBUG} -le 0 ] && return

    echo >&2 "DEBUG: ${@}"
}

function elpush() {
    decho "ELPUSH: ${1}"

    [ "${1%%:*}" != "BEGIN" ] && return 1

    stack+=("${1#*:}")
}

function elpop() {
    decho "ELPOP : ${1}"

    [ "${1%%:*}" != "END" ] && return 1

    [ "${stack[$(( ${#stack[@]} - 1 ))]}" != "${1#*:}" ] && return 2

    unset stack[${#stack[@]}]
}

function demultiline() {
    awk \
'
BEGIN { ORS=""; }                    # default: no newline between output records
NR==1 { print; next; }               # first line: print
/^[^ ]/ { print "\n"; print; next; } # if it doesnt start with a space: print newline before
{ sub(/^ /, ""); print; }            # other lines (next; has not been called yet)
'

}

# Load timezones
function loadtimezones() {
    read -r line

    [ "${line}" != "BEGIN:VCALENDAR" ] && {
        echo >&2 "ERROR: Expected 'BEGIN:VCALENDAR' not found"
        return 1
    }

    elpush "BEGIN:VCALENDAR"

    while read -r line; do #{
        key="${line%%:*}"
        value="${line#*:}"

        [ "${key}" == "BEGIN" ] && {
            elpush "${line}"
            continue
        }

        [ "${key}" == "END"   ] && {
            elpop "${line}"

            [ "${value}" == "VTIMEZONE" ]\
            && [ ! -z "${tzid}"  ]\
            && [ ! -z "${tzoff}" ]\
            && {
                tz[${tzid//[ \/\.]/_}]="${tzoff}"

                decho "SET TZ: \"${tzid}\" = ${tzoff}"
            }

            continue
        }

        stacktop="${stack[$(( ${#stack[@]} - 1 ))]}"
        stacknext=""
        [ ${#stack[@]} -ge 2 ] && stacknext="${stack[$(( ${#stack[@]} - 2 ))]}"

        [ "${stacktop}" == "VTIMEZONE" ] && {
            [ "${key}" == "TZID" ] && {
                decho "${key}: ${value}"
                tzid="${value}"
                tzid="${tzid//\"/}"
                continue
            }
        }

        # TODO: Process daylight and calculate WHEN it's daylight or not.

        [ "${stacknext}" == "VTIMEZONE" ]\
        && [ "${stacktop}" == "STANDARD" ]\
        && [ "${key}" == "TZOFFSETTO" ]\
        && {
            decho "${key}: ${value}"
            tzoff="${value}"
            continue
        }
    done #}
}

# Load calendar events
function loadevents() {
    summ=""
    loc=""

    read -r line

    [ "${line}" != "BEGIN:VCALENDAR" ] && {
        echo >&2 "ERROR: Expected 'BEGIN:VCALENDAR' not found"
        return 1
    }

    elpush "BEGIN:VCALENDAR"

    while read -r line; do #{
        key="${line%%:*}"
        value="${line#*:}"

        [ "${key}" == "BEGIN" ] && {
            elpush "${line}"
            continue
        }

        [ "${key}" == "END"   ] && {
            elpop "${line}"

            [ "${value}" == "VEVENT" ]\
            && [ ! -z "${summ}"  ]\
            && [ ! -z "${tm[0]}" ]\
            && {
                #    "DESCRIPTION: meh"
                spcs="             "

# NOTE: sed de'escapes '\,', '\;' and converts '\n' to newline.
cat <<EOF

[ NEW EVENT [
START      : ${tm[0]}
END        : ${tm[1]}
SUMMARY    : ${summ}
LOCATION   : ${loc}
DESCRIPTION: $(\
        echo "${desc}"\
        |sed 's#\\n#\n#g;s#\\,#,#g;s#\\;#;#g'\
        |fold -s -w $((80 - ${#spcs}))\
        |sed '2,$s#^#'"${spcs}"'#g'\
        )
] NEW EVENT ]
EOF
            }

            continue
        }

        stacktop="${stack[$(( ${#stack[@]} - 1 ))]}"
        stacknext=""
        [ ${#stack[@]} -ge 2 ] && stacknext="${stack[$(( ${#stack[@]} - 2 ))]}"


        [ "${stacktop}" == "VEVENT" ] && {
            # Inside event
            [ "${key%%;*}" == "SUMMARY"     ] && {
                decho "${key}: ${value}"
                summ="${value}"
                continue
            }

            [ "${key%%;*}" == "LOCATION"    ] && {
                decho "${key}: ${value}"
                loc="${value}"
                continue
            }

            [ "${key%%;*}" == "DESCRIPTION" ] && {
                decho "${key}: ${value}"
                desc="${value}"
                continue
            }

            # DTSTART;TZID=Arabian Standard Time:20160711T100000
            [ "${key%%;*}" == "DTSTART" ]\
            || [ "${key%%;*}" == "DTEND" ]\
            && {
                ctz=""

                # Walk through the key options
                tzp1="${key}"
                tzp2="${key}"
                while [ 1 ]; do #{
                    [ "${tzp2}" == "${tzp2#*;}" ] && break

                    tzp2="${tzp2#*;}"
                    [ "${tzp2:0:4}" == "TZID" ] && {
                        ctz="${tzp2%%;*}"
                        ctz="${ctz%%:*}"
                        ctz="${ctz//\"/}"
                        ctz="${ctz##*=}"

                        decho "${key%%;*}:TZ: ${ctz}"
                        [ -z "${tz[${ctz//[ \/\.]/_}]}" ] && {
                            echo >&2 "ERROR: Unknown timezone for ${key%%;*}: ${ctz}"
                            ctz=""
                        } || {
                            decho "- FOUND TZ: ${ctz}"
                            ctz="${tz[${ctz//[ \/\.]/_}]}"
                        }
                    }
                done #}

                # No time specified?
                [ ${#value} -lt 14 ] && value="${value}T000000"

                tmp="$(date -d "$(echo \
                        "${value:0:4}-${value:4:2}-${value:6:2}" \
                        "${value:9:2}:${value:11:2}:${value:13:2}" \
                        "${ctz}" \
                        )" \
                    +'%Y-%m-%d %H:%M %z' \
                )"

                decho "${key%%;*}: ${tmp}"

                [ "${key%%;*}" == "DTSTART" ] && tm[0]="${tmp}"
                [ "${key%%;*}" == "DTEND"   ] && tm[1]="${tmp}"

                continue
            }
        }

    done #}
}



# START #

# If debug file, redirect stderr out to it
[ ! -z "${ERROR_LOG}" ] && exec 2>>"${ERROR_LOG}"

decho "START"

# Check for wget
#check_for_cmd "COMMAND" "PACKAGE"



moreparams=1
decho "Processing ${#} params..."
while [ ${#} -gt 0 ]; do #{
    decho "Command line param: ${1}"

    [ ${moreparams} -gt 0 ] && {
        case "${1}" in #{
            # Verbose mode # [-v|--verbose]
            -v|--verbose)
                decho "Verbose mode specified"

                DEBUG=1

                shift 1; continue
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

            *)
                [ "${1}" == "--" ] && {
                    # No more parameters to come
                    moreparams=0
                    shift 1; continue
                }

                [ "${1}" == "-" ] && {
                    # Read stdin
                    set -- "/dev/stdin"
                    # FALL THROUGH TO FILE HANDLER BELOW
                }

                [ "${1:0:1}" == "-" ] && {
                    # Assume a parameter
                    echo >&2 "ERROR: Unrecognised parameter ${1}..."
                    exit ${ERR_UNKNOWNOPT}
                }
            ;;

        esac #}
    }

    # File
    decho "File specified ( ${1} )"
    files+=("${1}")
    shift 1
done #}

for f in "${files[@]}"; do #{
    decho "FILE: ${f}"
    [ "${f}" == "/dev/stdin" ] && {
        decho "PROCESS STDIN"
        f="$(dos2unix </dev/stdin|demultiline)"
    } || {
        decho "PROCESS FILE: ${f}"
        [ ! -r "${f}" ] && {
            echo >&2 "ERROR: Unable to read file ${f}..."
            continue
        }
        f="$(dos2unix <"${f}"|demultiline)"
    }

    loadtimezones < <(echo "${f}")
    loadevents    < <(echo "${f}")
done #}

decho "DONE"
