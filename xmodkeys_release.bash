#!/bin/bash
# vim:set tabstop=4 textwidth=80 shiftwidth=4 expandtab cindent cino=(0,ml,\:0:
# ( settings from: http://datapax.com.au/code_conventions/ )
#
#/**********************************************************************
#    XModKeys Relesae
#    Copyright (C) 2011-2017 Todd Harbour
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

# xmodkeys_release
# ----------------
# A simple script to release any X modifier keys that are currently pressed.
# Occasionally, when using synergy ( https://symless.com/synergy/ |
# https://github.com/symless/synergy ) I find that a modifier is showing as
# pressed when it isn't. This tool can release it for you (requires xdotool)
#
# Usage:
#     Easiest way to use it is probably to SSH into the afflicted machine, and
#     run (assuming your DISPLAY is :0.0):
#         DISPLAY=:0.0 xmodkeys_release

keysympath="/usr/include/X11/keysymdef.h"



# Get a list of all modifier keys
function getmodifierlist() {
    local chgfr='^#define XK_\([_a-zA-Z0-9]*_\(L\|R\|Level.*\)\) .*$'
    local chgto='\1'

    sed -n 's/'"${chgfr}"'/'"${chgto}"'/p' "${keysympath}"
}

# Do it
getmodifierlist|xargs xdotool keyup
