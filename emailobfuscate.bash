#!/bin/bash
# vim:set ts=4 sw=4 tw=80 et ai si cindent cino=L0,b1,(1s,U1,m1,j1,J1,)50,*90 cinkeys=0{,0},0),0],\:,!^F,o,O,e,0=break:
# ( settings from: http://datapax.com.au/code_conventions/ )
#
#/**********************************************************************
#    E-mail Obfuscate
#    Copyright (C) 2011-2025 Todd Harbour
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

# emailobfuscate
#---------------
# An obfuscater for email URIs, as anecdotally URIs encoded using encoded 2 byte
# hex characters don't seem to be picked up as much by spam scraper thingies.

# Config paths
_ETC_CONF="/etc/emailobfuscate.conf"
_HOME_CONF="${HOME}/.emailobfuscaterc"



############### STOP ###############
#
# Do NOT edit the CONFIGURATION below. Instead generate the default
# configuration file in your home directory thusly:
#
#     ./emailobfuscate.bash -C >~/.emailobfuscaterc
# or system wide:
#     ./emailobfuscate.bash -C >/etc/emailobfuscate.conf
#
####################################

# [ CONFIG_START

# E-mail Obfuscate Default Configuration
# ======================================

# DEBUG
#   This defines debug mode which will output verbose info to stderr
#   or, if configured, the debug file ( ERROR_LOG ).
DEBUG=0

# NOLINK
#   If set, output will be an HTML mailto: link. If not, only the address will
#   be output.
NOLINK=0

# ERROR_LOG
#   The file to output errors and debug statements (when DEBUG != 0) instead of
#   stderr.
#ERROR_LOG="/tmp/emailobfuscate.log"

# ] CONFIG_END

###
# Config loading
###
[ ! -z "${_ETC_CONF}"  ] && [ -r "${_ETC_CONF}"  ] && . "${_ETC_CONF}"
[ ! -z "${_HOME_CONF}" ] && [ -r "${_HOME_CONF}" ] && . "${_HOME_CONF}"

# Version
APP_NAME="E-mail Obfuscate (emailobfuscate)"
APP_VER="0.01"
APP_URL="http://gitlab.com/krayon/qdnxtools/emailobfuscate.bash"

# Program name
PROG="$(basename "${0}")"

# exit condition constants
ERR_NONE=0
ERR_MISSINGDEP=1
ERR_UNKNOWNOPT=2
ERR_INVALIDOPT=3
ERR_MISSINGPARAM=4

# Defaults not in config



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

${APP_NAME} obfuscates an email URI link using encoded 2 byte hex characters.
Anecdotally these don't seem to be picked up as much by spammers' email address
gathering web scrapers.

Usage: ${PROG} -h|--help
       ${PROG} -V|--version
       ${PROG} -C|--configuration
       ${PROG} [-v|--verbose] [-n|--nolink] [--] [-|<ADDY>]

-h|--help           - Displays this help
-V|--version        - Displays the program version
-C|--configuration  - Outputs the default configuration that can be placed in
                          ${_ETC_CONF}
                      or
                          ${_HOME_CONF}
                      for editing.
-v|--verbose        - Displays extra debugging information.  This is the same
                      as setting DEBUG=1 in your config.
-n|--nolink         - Don't output an HTML mailto: link, only the address
                      encoded.
<ADDY>              - The email address to encode. If no text is specified, or
                      <ADDY> is "-" (minus/hyphen), then the address(es) will be
                      read from stdin

Example: ${PROG} nevergonnagiveyouup@example.com
EOF
}

# Output configuration file
function output_config() {
    sed -n '/^# \[ CONFIG_START/,/^# \] CONFIG_END/p' <"${0}"
}

# Debug echo
function decho() {
    # Not debugging, get out of here then
    [ ${DEBUG} -le 0 ] && return

    echo "[$(date +'%Y-%m-%d %H:%M')] DEBUG: ${@}" >&2
}

# Encode a URL
function encodeurl() {
    url="${@}"

    out=""
    for (( i = 0; i < ${#url}; ++i )); do #{
        out="${out}$(printf '%%%2X' "'${url:${i}:1}'")"
    done #}

    echo "${out}"
}

# Encode an email address
function encodeaddy() {
    addy="${@}"

    out=""
    for (( i = 0; i < ${#addy}; ++i )); do #{
        out="${out}$(printf '&#x%.4X;' "'${addy:${i}:1}'")"
    done #}

    echo "${out}"
}

# Completely process one email address
function encodeone() {
    while read -r one; do #{
        out="$(encodeaddy "${one}")"

        [ "${NOLINK}" -ne 1 ] && {
            out="<a href="'"'"mailto:$(encodeurl "${one}")"'"'">${out}</a>"
        }

        echo "${out}"
    done #}
}



# START #

# If debug file, redirect stderr out to it
[ ! -z "${ERROR_LOG}" ] && exec 2>>"${ERROR_LOG}"

decho "START"

# Check for required commands

# Process params
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

            # No link # [-n|--nolink]
            -n|--nolink)
                decho "No link mode specified"

                NOLINK=1

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

            # Configuration output # -C|--configuration
            -C|--configuration)
                decho "Configuration"

                output_config
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
                    shift 1; continue
                }

                [ "${1:0:1}" == "-" ] && {
                    # Assume a parameter
                    echo "ERROR: Unrecognised parameter ${1}..." >&2
                    exit ${ERR_UNKNOWNOPT}
                }
            ;;

        esac #}
    }

    # URL
    decho "URL specified ( ${@} )"
    addy="${@}"
    break
done #}

# If URL is specified
[ ! -z "${addy}" ] && {
    echo "${addy}"|encodeone
    true

} || {
    encodeone </dev/stdin
}

decho "DONE"
