#!/system/bin/sh
# Copyright © 2020 The Android Open Source Project

#mount
function unmount_all() {
  (umount /system;
  if [ -d /system_root -a ! -f /system/build.prop ]; then
    umount /system_root;
  fi;
  umount /system;
  umount /vendor;
  umount /data) 2>/dev/null;
}

function mount_all(){
    mount -o rw,remount / 2>/dev/null;
    mount -o rw,remount /system 2>/dev/null;
    mount -o rw,remount /vendor 2>/dev/null;
    mount -o rw,remount /product 2>/dev/null;
    mount -o rw,remount /data 2>/dev/null;
    mount -o rw,remount /cust 2>/dev/null;
    mount -o rw,remount /system_root 2>/dev/null;
    #test -f /system/system/build.prop && root=/system;

    #A/B or SAR
    if [ -f /system/system/build.prop ] || [ -f /system_root/system/build.prop ]; then
        umount /system;
        umount /system 2>/dev/null;
        mkdir /system_root 2>/dev/null;
        mount -o rw,remount /dev/block/bootdevice/by-name/system /system_root;
        mount -o bind /system_root/system /system;
        #  unset root;
    fi;
}

#getconf "name" "file"
function getconf(){
    if [ -f $2 ];then
        local conf=`grep "$1=" $2 2>/dev/null`
    else
        local conf=''
    fi
    ##
    if [ -n "$conf" ];then
        conf_value=`grep "$1" $2 | cut -d'=' -f2`
    else
        unset conf_value 2>/dev/null
    fi
}

#check_command "applet" "number of commands"
function check_command(){
	[ "$#" -gt "$2" ] && echo "$1: Error, please print right command" && exit 1
}


#setconf "name1" "name2" "file"
function setconf(){
    local conf=`grep "$1=" $3`
    if [ -n "$conf" ];then
        sed -i "s#$1=*.*#$1=$2#" $3
    else
        echo -e "$1=$2" $3
    fi
}

function installbin(){
    case $1 in
    -f)
        if [ -n "$2" ];then
            local applet=`basename $2`
            cp -af $2 /system/bin/$applet
            chmod "755" /system/bin/$applet
            chown "root:shell" /system/bin/$applet 2>/dev/null
        else
            echo -e "installbin: bin file don't exist"
        fi;;
    *)
        if [ -n "$1" ] && [ ! -f "$1" ];then
            local applet=`basename $1`
            cp -af $1 /system/bin/$applet
            chmod "755" /system/bin/$applet
            chown "root:shell" /system/bin/$applet 2>/dev/null
        elif [ ! -n "$1" ];then
            echo -e "install_applet usage :\n    install_applet [-f | command] <command>"
            exit 1
        fi;;
    esac;
}


#rand "min" "max"
function rand(){
    [ ! -n "$1" ] && echo -e "rand: First command error" && exit 1
    [ ! -n "$2" ] && echo -e "rand: Second command error" && exit 1
    local max=$(($2-${1}+1))
    #增加一个10位的数再求余
    local num=$(($RANDOM+1000000000))
    randnum=`echo $(($num%$max+$1))`
}

function check_busybox(){
    local tool=/system/xbin/busybox
    if [ -f $tool ];then
        local listnum=`$tool --list | wc -l`
        rand "1" "$listnum"
        local applet=`$tool --list | sed -n "${randnum}p"`
        local a=`ls -l /system/xbin/$applet`
        if [ -n "$a" ];then      
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}


function install_busybox(){
    local tool=/system/xbin/busybox
    cp -af $1 $tool
    chmod "755" $tool
    chown "root:shell" $tool 2>/dev/null
    for line in `$tool --list`;do
        ln -fs $tool /system/xbin/$line
    done
}

function delete_busybox(){
	local tool=/system/xbin/busybox
	if [ ! -f $tool ];then
		echo -e "$1: '$tool' don't exist"
		return 1
	else
		for line in `$tool --list`;do
			rm -f /system/xbin/$line
		done
		rm -rf $tool
		return 0
	fi
}
