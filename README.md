# LinuxIntelAlteraArria10
This repository contains comprehensive guide and collection of scripts for building embedded Linux system for Intel® (Altera) . These steps were tested on **Terasic® HAN Pilot Platform** development board, but can be used with minor modifications for another boards using  Arria® 10 SocFPGA onboard. FPGA design is based on **a10s_ghrd** (HAN_v.1.0.5_HWrevE_SystemCD.zip).

https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=228&No=1133 

![Board](https://www.terasic.com.tw/attachment/archive/1133/image/han_45degree.jpg)


## Useful links

 ```
       https://rocketboards.org/foswiki/Documentation/BuildingBootloader
       https://qiita.com/SoCSoCSoC/items/33ee704938b6b4b554a2
       https://rocketboards.org/foswiki/Documentation/BuildingBootloader#Arria_10_SoC_45_Boot_from_SD_Card 
       https://titanwolf.org/Network/Articles/Article?AID=90314ac7-dd63-42a6-a4ce-527b847cce34#gsc.tab=0
       https://rocketboards.org/foswiki/Documentation/A10GSRDGeneratingUBootAndUBootDeviceTree 
       https://www.digikey.com/eewiki/display/linuxonarm/DE0-Nano-SoC+Kit
       https://github.com/ikwzm/FPGA-SoC-Linux/
       https://github.com/altera-opensource/
       http://xillybus.com/tutorials/device-tree-zynq-4
 ```
## 1] Install Linaro GCC toolchains and set paths

 ```
 wget https://releases.linaro.org/components/toolchain/binaries/7.5-2019.12/arm-linux-gnueabihf/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf.tar.xz
tar xf gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf.tar.xz
export PATH=`pwd`/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf/bin:$PATH
export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabihf-
 ```

Test cross compiler with: `${CC}gcc --version`

## 2] Bootloader u-boot git clone and branch checkout

 ```
git clone https://github.com/altera-opensource/u-boot-socfpga u-boot-socfpga
cd u-boot-socfpga
git checkout -b test-bootloader -t origin/socfpga_v2020.04
 ```

## 2] Quartus XML to header (.h) file conversion

Use provided script `qts-filter-a10.sh` for conversion of generated Intel® Quartus® XML design platform file. This file contains **Arria10 Hard Processor** and  **Arria10 External Memory Interface** settings.  You can modify these settings using **Intel Platform Designer** (previous known as QSys). Modify path setting for your FPGA design.

 ```
cd u-boot-socfpga
./arch/arm/mach-socfpga/qts-filter-a10.sh $HOME/a10s_ghrd/hps_isw_handoff/hps.xml arch/arm/dts/socfpga_arria10_socdk_sdmmc_handoff.h
Check: ls -al arch/arm/dts/socfpga_arria10_socdk_sdmmc_handoff.h
 ```

## 3] Build your u-boot
 ```
export ARCH=arm
make socfpga_arria10_defconfig
make -j $(nproc)

u-boot.img and u-boot-splx4.sfp --> cp later to final destination ...
 ```

## 4] SOF --> RBF conversion with FPGA Early I/O Release

Follow: https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/an/an-a10-soc-fpga-early-io-release.pdf

`The Intel® Arria® 10 SoC FPGA device supports Early I/O Release. This feature splits the FPGA configuration sequence into two parts. The first part configures the FPGA I/O, the Shared I/O and enables the HPS External Memory Interface (EMIF) if present. The second part of the sequence configures the FPGA fabric.`

**SOF to RBF vonversion script:** `rbf_conversion_a10.sh` (` --hps` option is important!)
 ```
#!/bin/bash 
QUARTUS_EXPORT_PATH=$HOME/a10s_ghrd/output_files
QUARTUS_EXPORT_PATH_BIN=$HOME/intelFPGA/18.1/quartus/bin/
QUARTUS_FIRMWARE_NAME="ghrd_10as066n2.rbf"

cd $QUARTUS_EXPORT_PATH
$QUARTUS_EXPORT_PATH_BIN/quartus_cpf  --convert --hps -o bitstream_compression=on a10s.sof $QUARTUS_FIRMWARE_NAME  
 ```

**u-boot final  FIT image creation:**
 ```
ln -s $HOME/a10s_ghrd/output_files/ghrd_10as066n2.core.rbf .
ln -s $HOME/a10s_ghrd/output_files/ghrd_10as066n2.periph.rbf .
cd u-boot-socfpga
tools/mkimage -E -f board/altera/arria10-socdk/fit_spl_fpga.its fit_spl_fpga.itb

fit_spl_fpga.itb --> cp later to final destination ...

Result:
--------
FIT description: FIT image with FPGA bistream
Created:         Mon Dec  7 19:05:40 2020
 Image 0 (fpga-periph-1)
  Description:  FPGA peripheral bitstream
  Created:      Mon Dec  7 19:05:40 2020
  Type:         FPGA Image
  Compression:  uncompressed
  Data Size:    360456 Bytes = 352.01 KiB = 0.34 MiB
  Load Address: unavailable
 Image 1 (fpga-core-1)
  Description:  FPGA core bitstream
  Created:      Mon Dec  7 19:05:40 2020
  Type:         FPGA Image
  Compression:  uncompressed
  Data Size:    14688852 Bytes = 14344.58 KiB = 14.01 MiB
  Load Address: unavailable
 Default Configuration: 'config-1'
 Configuration 0 (config-1)
  Description:  Boot with FPGA early IO release config
  Kernel:       unavailable
  FPGA:         fpga-periph-1
 ```

## 5] Linux kernel build (tested with socfpga-5.4.64-lts branch)

**Test config:** `config-socfpga-5.4.64-lts`

 ```
git clone https://github.com/altera-opensource/linux-socfpga/ socfpga-kernel-dev-4
cd socfpga-kernel-dev-4
git checkout socfpga-5.4.64-lts

make menuconfig 
Use and modify config-socfpga-5.4.64-lts ...
Save as .config 

export DTC_FLAGS=--symbols
make -j$(nproc) zImage modules
make socfpga_arria10_socdk_sdmmc.dtb

Create Debian packages: make -j$(nproc) deb-pkg

arch/arm/boot/zImage --> cp later to final destination ...
arch/arm/boot/dtssocfpga_arria10_socdk_sdmmc.dtb --> cp later to final destination ...
 ```

## 6] Linux RootFS based on Debian 10 (Buster)

**Debian RootFS build configuration:** `build-debian10-rootfs-with-qemu.sh`
 ```
sudo apt install qemu-user-static debootstrap binfmt-support
export targetdir=debian-10-rootfs-custom
export distro=buster

mkdir $targetdir

sudo debootstrap --arch=armhf --foreign $distro $targetdir
sudo cp /usr/bin/qemu-arm-static $targetdir/usr/bin
sudo cp /etc/resolv.conf $targetdir/etc
sudo cp scripts/build-debian10-rootfs-with-qemu.sh $targetdir
sudo cp image-5.4.59-armv7-fpga-dirty_5.4.59-armv7-fpga-dirty-1_armhf.deb $targetdir
sudo chroot $targetdir

run script: build-debian10-rootfs-with-qemu.sh
dpkg -i linux-image-5.6.0_5.6.0-1_armhf.deb linux-headers-5.6.0_5.6.0-1_armhf.deb

sudo tar cfz ../debian10-rootfs-vanilla.tgz *
 ```

## 7] Create SD card image

```
export DISK=/dev/sdb --> change to valid DISK volume !!!
sudo dd if=/dev/zero of=${DISK} bs=1M count=128

Partition using fdisk /dev/sdb {SDHC ~16GB example}: 

1) FAT32 --> 100 M
2) 0xA2  --> 10 M (special partition for u-boot-spl)
2) EXT4 Linux --> ~14.4G

Create FILE systems:
sudo mkfs.vfat -F 32 ${DISK}1
sudo mkfs.ext4 -L rootfs ${DISK}3

Write u-boot-splx4.sfp preloader to A2 partition: 
cd /u-boot-socfpga/spl/ 
sudo dd if=u-boot-splx4.sfp of=${DISK}2

Copy these files to FAT32 partition: 
-> fit_spl_fpga.itb
-> socfpga_arria10_socdk_sdmmc.dtb
-> u-boot.img
-> zImage
-> extlinux/exlinux.conf

Populate SD card with ROOT FS finally:

sudo tar xfz debian10-rootfs-vanilla.tgz -C /media/$USER/rootfs
sudo sync 
sudo chown root:root /media/$USER/rootfs/
sudo chmod 755 /media/$USER/rootfs/
```
## 8] Linux drivers and Device Tree Overlay

**Intel mSGDMA kernel DMA driver (Intel/Altera Streaming mode)** 
https://github.com/pavelfpl/altera_msgdma_st

**Intel/Altera GPIO universal SysFS driver**
https://github.com/pavelfpl/altera_gpio

 `HPS - only partial FPGA reconfiguration is supported from running Linux, use u-boot to program FPGA before boot using FIT image ...`

Partial reconfiguration - see: https://www.intel.co.jp/content/www/jp/ja/programmable/documentation/pne1482303525167.html

Device Tree Overlays for previous mSGDMA and GPIO drivers: `altera_msgdma_arria10.dts` 
```
DTC conversion (DTC->DTBO)
dtc -O dtb -o altera_msgdma_arria10.dtbo -b 0 -@ altera_msgdma_arria10.dts 

DTC load:
sudo ./dtc_overlay_load_a10.sh 

GPIO testing:
./gpio_test 1 
./gpio_test 2
./gpio_test 3
./gpio_test 0 

mSGDMA testing:
./altera_msgdma_test_v2 

Total Write/read bytes count: 40960000
Elapsed time: 648.864000 ms.
Combined speed W/R [MBytes/s]: 63.13
Combined speed W/R [Mbit/s]: 505.01
Single direction speed [Mbit/s]: 1010.01
```
## 9] a10s_ghrd FPGA design with mSGDMA loopback

For testing purpose FPGA design with mSGDMA ST loopback is provided. Tested with `Quartus 18.1.0`.

## 10] Advanced Linux configuration

- DHCP / static IP fallback
```
sudo vim.tiny /etc/dhcpcd.conf
----- End of file ------------
# define static profile
profile static_eth0
static ip_address=192.168.10.2/24    # Change 
static routers=192.168.10.1          # Change
static domain_name_servers=8.8.8.8   # Change

# fallback to static profile on eth0
interface eth0
fallback static_eth0
```
- WARNING: 'makeinfo' is missing on your system.
```
sudo apt install libncurses5-dev
sudo apt install texinfo gawk
```
- Arm DS5 debug errors with  `GDB server` from Debian distribution
```
Build and install: linaro-7.8-2014.09.tar.gz
```


