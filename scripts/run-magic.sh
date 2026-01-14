#!/bin/sh

if [ -z "${PDK}" ]; then
  echo "\$PDK is not set!"
  exit 1
fi

if [ -z "${PDK_ROOT}" ]; then
  echo "\$PDK_ROOT is not set!"
  exit 1
fi

export CORNER=$1

if [ -z "${CORNER}" ]; then
  echo "No CORNER specified as argument!"
  exit 1
fi

export SCRIPTS_DIR=$(pwd)/scripts
export REF_EXTRACTOR=magic

case "$PDK" in
  sky130A*)  export TECH_LEF=$PDK_ROOT/$PDK/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__$CORNER.tlef ;;
  gf180mcu*) export TECH_LEF=$PDK_ROOT/$PDK/libs.ref/gf180mcu_fd_sc_mcu7t5v0/techlef/gf180mcu_fd_sc_mcu7t5v0__$CORNER.tlef ;;
  ihp-sg13*) export TECH_LEF=$PDK_ROOT/$PDK/libs.ref/sg13g2_stdcell/lef/sg13g2_tech.lef ;;
  *)         echo "Unknown PDK: $PDK"; exit 1 ;;
esac

export EXT_DIR=$(pwd)/openrcx-$REF_EXTRACTOR/$PDK
export REF_SPEF=$EXT_DIR/blk.$PDK.$CORNER.spef
export EXT_RULES=$EXT_DIR/openrcx/rules.openrcx.$PDK.$CORNER.$REF_EXTRACTOR

echo "\$PDK: $PDK"
echo "\$PDK_ROOT: $PDK_ROOT"
echo "\$CORNER: $CORNER"
echo "\$REF_EXTRACTOR: $REF_EXTRACTOR"
echo "\$TECH_LEF: $TECH_LEF"
echo "\$EXT_DIR: $EXT_DIR"
echo "\$REF_SPEF: $REF_SPEF"
echo "\$EXT_RULES: $EXT_RULES"

mkdir -p $EXT_DIR/openrcx

# Generate patterns for calibration
openroad $SCRIPTS_DIR/generate_patterns.tcl 

\mv rulesGen.log $EXT_DIR

# Use magic for extraction and convert to SPEF
$SCRIPTS_DIR/make_spef_file.sh $EXT_DIR/patterns.def $CORNER

# Generate OpenRCX RC rule file based on SPEF
openroad $SCRIPTS_DIR/generate_rules.tcl 

# Use OpenRCX for extraction and diff the result with magic
openroad $SCRIPTS_DIR/extract_patterns.tcl 

\mv ./diff_spef.out $EXT_DIR/diff-spef.openrcx.$PDK.$CORNER.$REF_EXTRACTOR.out
\mv ./diff_spef.log $EXT_DIR/diff-spef.openrcx.$PDK.$CORNER.$REF_EXTRACTOR.log

\rm rulesGen.log 



