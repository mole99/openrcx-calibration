#!/bin/sh
#
# make_spef_file.sh ---
#
#    Script to generate a .spef file from a pattern layout (in DEF format)
#    for openRCX using magic
#
# Usage:
#
#    make_spef_file.sh <DEF_file> [<corner>]

if test "$#" -eq 0 ; then
    echo "Usage: make_spef_file.sh <def_file_name> [<corner>]"
    echo "    where <corner> is 'nom' (default), 'min', or 'max'".
    exit 0
fi

if [ -z "${PDK}" ]; then
  echo "\$PDK is not set!"
  exit 1
fi

if [ -z "${PDK_ROOT}" ]; then
  echo "\$PDK_ROOT is not set!"
  exit 1
fi

def_file_name=$1

if [ -z "${def_file_name}" ]; then
  echo "No def_file_name specified as argument!"
  exit 1
fi

# Default extraction style is nominal
extstyle="'ngspice()'"
corner="nom"

if test "$#" -eq 2 ; then
    corner="$2"
    if test "$2" = "min" ; then
        extstyle="ngspice\(lrlc\)"
        corner="min"
    elif test "$2" = "max" ; then
        extstyle="ngspice\(hrhc\)"
        corner="max"
    fi
fi

export PDK_PATH=${PDK_ROOT}/${PDK}
export EXT_DIR=${EXT_DIR:=./openrcx-magic}

echo "\$PDK: $PDK"
echo "\$PDK_ROOT: $PDK_ROOT"
echo "\$EXT_DIR: $EXT_DIR"

mkdir -p $EXT_DIR

# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH=$(dirname "$SCRIPT")
echo $SCRIPTPATH

designname=`cat $def_file_name | grep ^DESIGN | cut -d' ' -f 2`

echo "Extracting design $designname from $def_file_name using magic, $corner corner"
magic -dnull -noconsole -rcfile ${PDK_PATH}/libs.tech/magic/${PDK}.magicrc << EOF
drc off
crashbackups stop
lef read ${TECH_LEF}
def read $def_file_name
extract style $extstyle
extract do aliases
extract do local
extract all
quit -noprompt
EOF

echo "Extraction done."

mv ${designname}.ext $EXT_DIR/${designname}.$PDK.$corner.ext

echo "Converting design $designname to SPEF"
${SCRIPTPATH}/ext2spef.py ${EXT_DIR}/${designname}.${PDK}.$corner.ext $EXT_DIR/${designname}.${PDK}.$corner.spef

echo "Done!"
exit 0
