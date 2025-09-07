#!/bin/bash
# vim:set ts=4 sw=4 tw=80 et ai si cindent cino=L0,b1,(1s,U1,m1,j1,J1,)50,*90 cinkeys=0{,0},0),0],\:,!^F,o,O,e,0=break:

# Replaces "{:toc}" in the input with a Table of Contents generated from the
# markdown headings found in the input.
# 
# NOTE: Skips non-contiguous headings (those that are not shallower, or
# _exactly_ one deeper.

# Version v0.0.1

generate_toc() {
    #$ echo '# -  @-Shell --scripting @ -guide?'|sed 's/^# *\(.*\)$/\1/;s#[^-A-Za-z_0-9]# #g;s# \+#-#g;s#-\+#-#g;s#.*#\L&#;s#^-##;s#-$##'

    local level=0
    local lc line h
    while IFS='\n' read -r line; do #{
        line="${line//$'\t'/ }"
        lc="${line%% *}" 
        line="${line#* }" 
    
        [ ${level} -eq 0 ] && level=${#lc}
    
        # Skip large immediate changes in depth
        [ $(( level + 1 )) -lt ${#lc} ] && continue
    
        # Store current level
        level=${#lc}
    
        h="${lc//#/  }"; h="${h:2}"
    
        echo -n "${h}- "
    
        sed 's#[^-A-Za-z_0-9 ]##g;s# \+#-#g;s#-\+#-#g;s#.*#\L&#;s#^-##;s#-$##' <<<"${line}"
    done < <(sed -n '/^#/p') #}
}

mddata=""
while IFS='\n' read -r line; do #{
    mddata="${mddata}${line}"$'\n'
done #}
mddata="${mddata:0: -1}"

toc="$(generate_toc <<<"${mddata}")"

sed 's#{:toc}#'"${toc//$'\n'/\\n}"'#' <<<"${mddata}"
