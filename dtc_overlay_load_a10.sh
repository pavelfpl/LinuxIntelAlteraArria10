#!/bin/bash

# ----------------------------------------------------------------
# Device Tree Overlay loader script - Intel/Altera SocFPGA A10 ...
# Pavel Fiala - 2020
# ----------------------------------------------------------------

DTC_OVERLAY_BASE_FILE="altera_msgdma_arria10.dtbo" 
DTC_OVERLAY_DIR="/sys/kernel/config/device-tree/overlays/fpga"
DTC_OVERLAY_FILE="/sys/kernel/config/device-tree/overlays/fpga/path"

start() {
	echo "Applying SoC FPGA Arria 10 Devicetree overlay ..."
	echo "-------------------------------------------------"
	
	if [ ! -d "$DTC_OVERLAY_DIR" ]; then
        mkdir $DTC_OVERLAY_DIR
    else
        rmdir $DTC_OVERLAY_DIR
        mkdir $DTC_OVERLAY_DIR        
    fi
    
    echo "Applying DTC file: "$DTC_OVERLAY_BASE_FILE
    
    echo $DTC_OVERLAY_BASE_FILE > $DTC_OVERLAY_FILE

}

stop() {
	echo "Removing SoC FPGA Arria 10 Devicetree overlay ..."
	echo "-------------------------------------------------"
	rmdir /sys/kernel/config/device-tree/overlays/fpga 
}

restart() {
        stop
        start
}

case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  restart|reload)
        restart
        ;;
  *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
esac

exit $?

