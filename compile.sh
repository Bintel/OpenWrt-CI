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
    echo "src-git helloworld https://github.com/fw876/helloworld" >> ./feeds.conf.default
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    cd ..
    PrintMessage "Preparing the source code is done. Time used: "
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
