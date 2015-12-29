#!/bin/sh

if type shopt > /dev/null 2>&1; then
    shopt -s xpg_echo
fi

sp=""
gen() {
    if test $# -gt 1; then
        echo "${sp}Module['postRun'] = function() {"
        sp="$sp  "
        gen ${*#$1}
        sp=${sp%  }
        echo "${sp}}"
    fi
    test -n "$sp" && echo "${sp}Module['calledRun'] = false;"
    echo "${sp}Module['print']('\\\n$1:');"
    echo "${sp}loadBinary('$1.wasm', onload.bind(null, '$1.js'));"
}

echo "document.addEventListener('DOMContentLoaded', function () {"
gen "$@"
echo "});"
