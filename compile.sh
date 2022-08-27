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
    
    sed -i 's/\tqxwlan_e2600ac \\/\tqxwlan_e2600ac \\\n\tredmi_ax6 \\\n\txiaomi_ax3600 \\\n\txiaomi_ax9000 \\/' ./package/firmware/ipq-wifi/Makefile
    sed -i 's/$(eval $(call generate-ipq-wifi-package,qxwlan_e2600ac,Qxwlan E2600AC))/$(eval $(call generate-ipq-wifi-package,qxwlan_e2600ac,Qxwlan E2600AC))\n$(eval $(call generate-ipq-wifi-package,redmi_ax6,Redmi AX6))\n$(eval $(call generate-ipq-wifi-package,xiaomi_ax3600,Xiaomi AX3600))\n$(eval $(call generate-ipq-wifi-package,xiaomi_ax9000,Xiaomi AX9000))/' ./package/firmware/ipq-wifi/Makefile
    
    cp -f ../board/* ./package/firmware/ipq-wifi/
    
    sed -i 's/qnap,301w)/xiaomi,ax3600|\\\nredmi,ax6)\n\tucidef_set_led_netdev "wan" "WAN" "blue:network" "eth0"\n\t;;\nqnap,301w)/' ./target/linux/ipq807x/base-files/etc/board.d/01_leds
    sed -i '/ipq807x_setup_interfaces()/,/ucidef_set_interfaces_lan_wan "eth0" "eth1"/s/;;/;;\n\tredmi,ax6|\\\n\txiaomi,ax3600)\n\t\tucidef_set_interfaces_lan_wan "eth1 eth2 eth3" "eth0"\n\t\t;;/' ./target/linux/ipq807x/base-files/etc/board.d/02_network
    
    cp -f ../hotplug/* ./target/linux/ipq807x/base-files/etc/hotplug.d/firmware/
    
    sed -i 's/\tqnap,301w)/\tqnap,301w|\\\n\tredmi,ax6|\\\n\txiaomi,ax3600|\\\n\txiaomi,ax9000)/' ./target/linux/ipq807x/base-files/etc/hotplug.d/firmware/11-ath11k-caldata
    
    sed -i 's/\tzte,mf269)/\tredmi,ax6|\\\n\txiaomi,ax3600|\\\n\txiaomi,ax9000)\n\t\tpart_num="$(fw_printenv -n flag_boot_rootfs)"\n\t\tif [ "$part_num" -eq "1" ]; then\n\t\t\tCI_UBIPART="rootfs_1"\n\t\t\ttarget_num=1\n\t\t\t# Reset fail flag for the current partition\n\t\t\t# With both partition set to fail, the partition 2 (bit 1)\n\t\t\t# is loaded\n\t\t\tfw_setenv flag_try_sys2_failed 0\n\t\telse\n\t\t\tCI_UBIPART="rootfs"\n\t\t\ttarget_num=0\n\t\t\t# Reset fail flag for the current partition\n\t\t\t# or uboot will skip the loading of this partition\n\t\t\tfw_setenv flag_try_sys1_failed 0\n\t\tfi\n\n\t\t# Tell uboot to switch partition\n\t\tfw_setenv flag_boot_rootfs $target_num\n\t\tfw_setenv flag_last_success $target_num\n\n\t\t# Reset success flag\n\t\tfw_setenv flag_boot_success 0\n\n\t\tnand_do_upgrade "$1"\n\t\t;;\n\tzte,mf269)/' ./target/linux/ipq807x/base-files/lib/upgrade/platform.sh
    
    cp -f ../dts/* ./target/linux/ipq807x/files/arch/arm64/boot/dts/qcom/
    
    sed -i 's/define Device\/zte_mf269/define Device\/redmi_ax6\n\t$(call Device\/xiaomi_ax3600)\n\tDEVICE_VENDOR := Redmi\n\tDEVICE_MODEL := AX6\n\tDEVICE_PACKAGES := ipq-wifi-redmi_ax6 uboot-envtools\nendef\nTARGET_DEVICES += redmi_ax6\n\ndefine Device\/xiaomi_ax3600\n\t$(call Device\/FitImage)\n\t$(call Device\/UbiFit)\n\tDEVICE_VENDOR := Xiaomi\n\tDEVICE_MODEL := AX3600\n\tBLOCKSIZE := 128k\n\tPAGESIZE := 2048\n\tDEVICE_DTS_CONFIG := config@ac04\n\tSOC := ipq8071\n\tDEVICE_PACKAGES := ath10k-firmware-qca9887-ct ipq-wifi-xiaomi_ax3600 \\\n\tkmod-ath10k-ct uboot-envtools\nendef\nTARGET_DEVICES += xiaomi_ax3600\n\ndefine Device\/zte_mf269/' ./target/linux/ipq807x/image/generic.mk
    
    sed -i 's/@@ -3,6 +3,9 @@ dtb-$(CONFIG_ARCH_QCOM)	+= apq8016-sbc.d/@@ -3,6 +3,11 @@ dtb-$(CONFIG_ARCH_QCOM)	+= apq8016-sbc.d/' ./target/linux/ipq807x/patches-5.10/900-arm64-dts-add-OpenWrt-DTS-files.patch
    sed -i 's/+dtb-$(CONFIG_ARCH_QCOM)	+= ipq8072-301w.dtb/+dtb-$(CONFIG_ARCH_QCOM)	+= ipq8072-301w.dtb\n+dtb-$(CONFIG_ARCH_QCOM)	+= ipq8071-ax6.dtb\n+dtb-$(CONFIG_ARCH_QCOM)	+= ipq8071-ax3600.dtb/' ./target/linux/ipq807x/patches-5.10/900-arm64-dts-add-OpenWrt-DTS-files.patch
    
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
