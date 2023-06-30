#!/bin/bash
TIMEFORMAT="%E"
BASEPATH=$(dirname `realpath $BASH_SOURCE`)
CURRENTPATH=`pwd`
Main()
{
    if [ $# -eq 0 ]
    then
        PrintMessage "Please enter target as argument.\n"
        exit 1
    fi
    cd $BASEPATH
    rm -rf ./openwrt/
    df -h
    time Prepare
    for arg in $@
    do
        time Compile $arg
    done
    df -h
    cd $CURRENTPATH
}
Prepare()
{
    PrintMessage "Preparing the source code...\n"
    git clone --depth 1 https://github.com/coolsnowwolf/lede openwrt
    cd ./openwrt
    time Customize
    echo "src-git helloworld https://github.com/fw876/helloworld" >> ./feeds.conf.default
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    cd ..
    PrintMessage "Preparing the source code is done. Time used: "
}
Customize()
{
    PrintMessage "Customizing the source code...\n"
    sed -i 's/define Device\/zte_mf269/define Device\/redmi_ax6\n\t$(call Device\/xiaomi_ax3600)\n\tDEVICE_VENDOR := Redmi\n\tDEVICE_MODEL := AX6\n\tDEVICE_PACKAGES := ipq-wifi-redmi_ax6 uboot-envtools\nendef\nTARGET_DEVICES += redmi_ax6\n\ndefine Device\/xiaomi_ax3600\n\t$(call Device\/FitImage)\n\t$(call Device\/UbiFit)\n\tDEVICE_VENDOR := Xiaomi\n\tDEVICE_MODEL := AX3600\n\tBLOCKSIZE := 128k\n\tPAGESIZE := 2048\n\tDEVICE_DTS_CONFIG := config@ac04\n\tSOC := ipq8071\n\tDEVICE_PACKAGES := ath10k-firmware-qca9887-ct ipq-wifi-xiaomi_ax3600 \\\n\tkmod-ath10k-ct uboot-envtools\nendef\nTARGET_DEVICES += xiaomi_ax3600\n\ndefine Device\/zte_mf269/' ./target/linux/ipq807x/image/generic.mk
    PrintMessage "Customizing the source code is done. Time used: "
}
Compile()
{
    local platform=$1
    PrintMessage "Compiling the firmware for $platform...\n"
    cd ./openwrt
    cat ../luci-app.config ../targets/$platform.config > ./.config
    make defconfig
    make download -j$(nproc) || make download -j1 V=s
    make -j$(nproc) || make -j1 V=s
    mv ./.config ./$platform.config
    cd ..
    PrintMessage "Compiling the firmware for $platform is done. Time used: "
}
PrintMessage()
{
    local message=$1
    echo -n -e "\033[0;34m$message\033[0m"
}
Main $@
