#!/bin/bash
# vim:set ts=4 sw=4 tw=80 et cindent ai si cino=(0,ml,\:0:
# ( settings from: http://datapax.com.au/code_conventions/ )
#
#/**********************************************************************
#    MagPi DL
#    Copyright (C) 2014-2017 Todd Harbour
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

# magpidl
#--------
# Downloader for The MagPi Magazine

urlbase="http://www.raspberrypi.org/magpi-issues/MagPi%issue%.pdf"

nowish="$(date +%Y-%m)"
last="$(ls -1 Issue*pdf|tail -1)"
i="${last#*_}"; i="${i%%_*}"
d="${last##*_}"; d="${d%.*}"
echo "Last downloaded issue is $i for $d"

[ "${d}" == "${nowish}" ] && {
    echo "Up to date, nothing to download"
    exit 0
}

while [ "${d}" != "${nowish}" ]; do #{
    i=$((${i} + 1))
    d="$(date -d "${d}-01 + 1 month" +%Y-%m)"
    newfile="Issue_${i}_-_${d}.pdf"
    url="${urlbase/\%issue\%/${i}}"

    echo "Downloading issue ${i} ($d)..."
    wget -q -c -O "${newfile}" "${url}"
done #}
