#!/bin/bash
# vim:set ts=4 sw=4 tw=80 et ai si cindent cino=L0,b1,(1s,U1,m1,j1,J1,)50,*90 cinkeys=0{,0},0),0],\:,!^F,o,O,e,0=break:
# ( settings from: http://datapax.com.au/code_conventions/ )
#
#/**********************************************************************
#    MagPi DL
#    Copyright (C) 2014-2025 Todd Harbour
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

# date -d "$(wget -q -S --spider https://www.raspberrypi.org/magpi-issues/MagPi56.pdf 2>&1|grep Last-Modified:|cut -d: -f2-) + 1 month" +%Y-%m
# 2017-04


# magpidl
#--------
# Downloader for The MagPi Magazine

fileformat="Issue_-_%issue%_-_%date%.pdf"

urlbase="http://www.raspberrypi.org/magpi-issues/MagPi%issue%.pdf"

# grep regex
gfr="$(echo "${fileformat}"|sed 's#%issue%#\([0-9]\*\)#;s#%date%#\([0-9]\{4\}-[0-9]\{2\}\)#')"
# sed  regex
sfr="$(echo "${fileformat}"|sed 's#%issue%#\\([0-9]\*\\)#;s#%date%#\\([0-9]\\{4\\}-[0-9]\\{2\\}\\)#')"

ls -1|egrep "${gfr}"|sed -n 's#'"${sfr}"'#\1 \2#gp'

exit 0







nowish="$(date +%Y-%m)"
list="$(ls -1 Issue*pdf 2>/dev/null)" && {
    last="$(echo "${list}"|tail -1)"

    # Get issue number
    i="${last#*_}"; i="${i%%_*}"

    # Get issue date
    d="${last##*_}"; d="${d%.*}"

    echo "Last downloaded issue is $i for $d"
} || {
    # Haven't downloaded any yet, so start at the first issue
    i=0
    d="2013-04"
}

# Remove issue number leading zero (if present)
[ "${i:0:1}" == "0" ] && i="${i:1}"

# If we've already got this months
[ "${d}" == "${nowish}" ] && {
    echo "Up to date, nothing to download"
    exit 0
}

while [ "${d}" != "${nowish}" ]; do #{
    i=$((${i} + 1)); ii=$i
    [ ${#ii} -lt 2 ] && ii="0${ii}"
    d="$(date -d "${d}-01 + 1 month" +%Y-%m)"
    newfile="Issue_${ii}_-_${d}.pdf"
    url="${urlbase/\%issue\%/${ii}}"

    echo "Downloading issue ${ii} ($d)..."
    wget -q -c -O "${newfile}" "${url}"
done #}
