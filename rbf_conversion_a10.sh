#!/bin/bash 
QUARTUS_EXPORT_PATH=$HOME/build_sockit_arm_2/a10s_ghrd/output_files
QUARTUS_EXPORT_PATH_BIN=$HOME/intelFPGA/18.1/quartus/bin/
QUARTUS_FIRMWARE_NAME="ghrd_10as066n2.rbf"

cd $QUARTUS_EXPORT_PATH
$QUARTUS_EXPORT_PATH_BIN/quartus_cpf  --convert --hps -o bitstream_compression=on a10s.sof $QUARTUS_FIRMWARE_NAME  
