#!/bin/bash

# ----------------------------------------------------------------
# GPIO test - Intel/Altera SocFPGA A10 ...
# Pavel Fiala - 2020
# ----------------------------------------------------------------

GPIO_NUM=$1
echo $GPIO_NUM > /sys/bus/platform/drivers/altera_gpio/ff200120.gpio1/altera_gpio

