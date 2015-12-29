#!/bin/sh

test $# -gt 0 || exit

if test "$1" != "-o"; then
    SRC=$1
    HTML=${SRC%.*}.html
    shift
fi

if test "$1" = "-o"; then
    HTML=$2
    test ${HTML%.html} = ${HTML} && HTML=${HTML}.html
    shift 2
    test -z "$SRC" && SRC=$1 && shift
fi

ASMJS=${HTML%.html}.asm.js
WASM=${HTML%.html}.wasm
PACKER=${PACKER:-third_party/polyfill-prototype-1/tools/pack-asmjs-v8}

CC=emcc
EXT=${SRC##*.}
if test "$EXT" = "cpp" -o "$EXT" = "cc" -o "$EXT" = "C"; then
    CC=em++
fi

$CC -O2 -g2 "$SRC" -o "$HTML" --separate-asm $* # -s PRECISE_F32=1

#WAST=${SRC%.*}.wast
#binaryen/bin/asm2wasm "$ASMJS" > "$WAST"
#sexpr-wasm-prototype/out/sexpr-wasm "$WAST" -o "$WASM"
#exit

main=0
IFS=""
while read -r line; do
    test "$line" != "${line%(function(global,env,buffer) \{}" && line="(function(global,env,buffer) {"
    test "$line" = "// EMSCRIPTEN_START_FUNCS" && line="\
  var getSTACKTOP = env.getSTACKTOP;
  var getSTACK_MAX = env.getSTACK_MAX;
  var getTempDoublePtr = env.getTempDoublePtr;
  var getABORT = env.getABORT;
  var getCttz_i8 = env.getCttz_i8;

$line

function _env_init() {
 STACKTOP = getSTACKTOP()|0;
 STACK_MAX=getSTACK_MAX()|0;
 tempDoublePtr=getTempDoublePtr()|0;
 ABORT=getABORT()|0;
 cttz_i8 = getCttz_i8()|0;
}"
    test "$line" != "${line#function _main(}" && main=1
    test "$line" != "${line%= STACKTOP;}" -a $main -eq 1 && main=0 && line=" _env_init();
$line"
    echo "$line"
done < "$ASMJS" > /tmp/$$.asm.js

"$PACKER" /tmp/$$.asm.js "$WASM"
rm -f /tmp/$$.asm.js
