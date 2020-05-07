#!/system/bin/sh
# Copyright © 2020 yanbuyu's Open Source Project

##字符完全不转义，包括\n \r等
function catstring(){
cat <<EOF
$1
EOF
}

##转义/ # [ ] ( )
function escape(){
local info=`catstring "$1" | sed 's/#/\\\#/g;s#-#\\-#g;s#\/#\\\/#g;s#\[#\\\[#g;s#\]#\\\]#g;s#(#\\\(#g;s#)#\\\)#g'`
cat <<EOF
$info
EOF
}

##转义# []
function catforsed(){
local info=`catstring "$1" | sed 's/#/\\\#/g;s#\[#\\\[#g;s#\]#\\\]#g'`
cat <<EOF
$info
EOF
}

##转义# / []
function catforsed_n(){
local info=`catstring "$1" | sed 's/#/\\\#/g;s#\/#\\\/#g;s#\[#\\\[#g;s#\]#\\\]#g'`
cat <<EOF
$info
EOF
}

##转义#
function catforecho(){
local info=`catstring "$1" | sed 's/#/\\\#/g'`
cat <<EOF
$info
EOF
}

##彩色输出
#echocolor "log"
function echocolor(){
    local a=`catstring "$1" | grep -E ":|："`
    [ ! -n "$a" ] && echo -e "\033[35m${1}\033[0m" && return 1
    local b=`catstring "$1" | sed 's#：#:#g'`
    local applet=`catstring "$b" | cut -d':' -f1 | sed '/^[[:space:]]$/d' | sed -n '1p'`
    local info=`catforecho "$b" | sed -r "s#^${applet}:##;s#^${applet}[[:space:]]+:##"`
    local c=`catstring "$1" | grep -i -E "warnning|error|erroneous|don't|didn't|isn't|aren't|wasn't|weren't|won't|can't|couldn't|right command|fail"`
    if [ -n "$c" ];then
        echo -e "\033[36m${applet}:\033[0m\033[31m${info}\033[0m"
    else
        echo -e "\033[36m${applet}:\033[0m\033[33m${info}\033[0m"
    fi
}

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

#check_command "applet" "all commands" "number of commands"
function check_command(){
	[ "$2" -gt "$3" ] && echocolor "$1: Error, please print right command" && exit 1
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
        else
            echocolor "installbin: Can't find [$2] file"
        fi;;
    *)
        if [ -f "$1" ];then
            local applet=`basename $1`
            cp -af $1 /system/bin/$applet
            chmod "755" /system/bin/$applet
        else
            echocolor "install_applet usage:\n    install_applet [-f | command] <command>"
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

#install busybox after check
function check_install_busybox(){
    check_busybox
    case $? in
        0)
            echocolor "check_install_busybox: [/system/xbin/busybox] already installed";;
        1)
            install_busybox "${env_bin_dir}/busybox"
            echocolor "check_install_busybox: [/system/xbin/busybox] installed successfully";;
        *)
            echocolor "check_install_busybox: Error, [install_busybox] function is erroneus"
            exit 4;;
    esac;
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
		echocolor "$1: Can't find '$tool'"
		return 1
	else
		for line in `$tool --list`;do
			rm -f /system/xbin/$line
		done
		rm -rf $tool
		return 0
	fi
}

##install_bin_chmod "applet name"
function install_bin_chmod(){
    install_bin_module "$1" >/system/bin/$1
    chmod "755" /system/bin/$1
}

##check_number "number"
function check_number(){
    [ ! -n "$1" ] && return 1
    local name=`catstring "$1" | sed -n '1p' | sed -n '/^[0-9]$/p;'`
    local name2=`catstring "$1" | sed -n '1p' | sed -n -r '/^[1-9][0-9]+$/p;'`
    if [ ! -n "$name" ] && [ ! -n "$name2" ];then
        return 1
    else
        return 0
    fi
}

#sedpro_r "string" "strings" "path" "[number]"
function sedpro_r(){
    local check_command_line=`echo -e "$2" | wc -l`
    if [ "$check_command_line" -gt "1" ];then
        local lines2line_tmp=`catstring "$2" | sed ':a;N;$!ba;s/\n/㼽砖-嚴不語/g'`
        local lines2line=`catforsed "$lines2line_tmp"`
    else
        local lines2line=`catforsed "$2"`
    fi
	local sedpro_newline=`catforsed "$1"`
    sed -i "${4}  s#${sedpro_newline}#${lines2line}#g;s#㼽砖-嚴不語#\n#g" $3
}

function sedpro_getnumber(){
    unset sedpro_extra sedpro_number sedpro_operation
    local sedpro_tmp_A=`catstring "$1" | grep ";"`
    if [ ! -n "$sedpro_tmp_A" ];then
        sedpro_extra="$1"
        return 0
    else
        local sedpro_common=`catstring "$1" | rev | cut -d';' -f1 | sed 's/ //g' | rev`
    fi
    sedpro_number=`catstring "$sedpro_common" | grep -E -o '^\+[0-9]+|^\-[0-9]+' | sed 's#-##;s#+##'`
    [ -n "$sedpro_number" ] && sedpro_operation=`catstring "$sedpro_common" | sed "s#${sedpro_number}##" | grep -E -o "^\+|-\$"`
    if [ -n "$sedpro_number" ] && [ -n "$sedpro_operation" ];then
        sedpro_extra="${1%;*}"
    else
        sedpro_extra="$1"
    fi
}

##for example: dekey "$contents" "content" 
function dekey(){
    dekey_tmp_line=1
    dekey_tmp_newline=1
    for dekey_tmp_A in `catstring "$1" | sed -r 's#[[:space:]]#一㼽砖#g'`;do
        dekey_tmp_B=`catstring "$dekey_tmp_A" | sed 's#一㼽砖# #g'`
        eval ${2}${dekey_tmp_line}="\${dekey_tmp_B}"
        dekey_tmp_line=$(($dekey_tmp_line + 1))
        dekey_tmp_C=`echo -e "$dekey_tmp_B" | grep '\.smali\$'`
        if [ -n "$dekey_tmp_C" ];then
            dekey_tmp_FF=`echo -e "$dekey_tmp_B" | sed -r "s#smali_classes[0-9]+/#smali/#"`
            dekey_smalipathbak=`echo -e "${dekey_tmp_FF#*smali/}"`
            dekey_smalipathlong=`echo -e "$dekey_smalipathbak" | sed "s#\.smali##"`
            dekey_tmp_long="L${2}"
            eval ${dekey_tmp_long}${dekey_tmp_newline}="L\${dekey_smalipathlong}"
            dekey_tmp_newline=$(($dekey_tmp_newline + 1))
        fi
    done
}

function runjava(){
    java -Xmx1024m -Djava.io.tmpdir=$JAVACACHE "$@"
}

function apktool(){
    runjava -jar "$APKTOOL" "$@"
}

function baksmali(){
    runjava -jar "$BAKSMALI" "$@"
}

function apkcompile(){
    unset apktool_perfix apktool_suffix
    local apktool_check=`catstring "$1" | grep "\."`
    [ ! -n "$1" ] && echocolor "${2}: Error, [$1] don't exist" && exit 1
    [ ! -n "$apktool_check" ] && echocolor "${2}: Error, [$1] format error" && exit 2
    apktool_perfix=`echo "${1%.*}"`
    apktool_suffix=`echo "${1##*.}"`
}

function checkdex(){
    local apktool_extractdex=`unzip -l $WORK/$1 | awk -F '[ ]+' '{print $5}' | sed '/\.dex$/!d' | sed '/^classes/d'`
    if [ -n "$apktool_extractdex" ];then
        catstring "$apktool_extractdex" | while read apktool_file;do
            unzip -q -o $WORK/$1 "$apktool_file" -d "$WORK"
            zip -d -q $WORK/$1 "$apktool_file"
            echo -e "$WORK/$1 -> $apktool_file" >>$CACHE/extractdex_cache
            echocolor "$2: Extracted other dex into [$WORK]"
        done
    fi
}

##adddex "apk name" "apk path" "function name"
function adddex(){
    if [ -f $CACHE/extractdex_cache ];then
        cat $CACHE/extractdex_cache | while read apktool_line;do
            local apktool_apk=`echo -e "$apktool_line" | awk -F '[ ]+' '{print $1}'`
            local apktool_file=`echo -e "$apktool_line" | awk -F '[ ]+' '{print $3}'`
            local apktool_apk_basename=`basename "$apktool_apk"`
            if [ "$1" == "$apktool_apk_basename" ];then
                cd $WORK
                [ -f ./$apktool_file ] && zip -q -r $2 ./$apktool_file
                echocolor "$3: Add [$apktool_file] into [$1]"
            fi
        done
    fi
}


#获取apk反编译后文件的md5值
#getmd5 "目录路径"
function getmd5(){
    #开始
    rm -f $CACHE/md5_cache
    echo -e "$1" | while read dir;do
        if [ -d $dir ];then
            md5sum $dir/* >>$CACHE/md5_cache
        fi
    done
    [ -f $CACHE/md5_cache ] && filemd5=`cat $CACHE/md5_cache`
    rm -f $CACHE/md5_cache
    if [ -n "$filemd5" ];then
        echocolor "$2: Got the [res/xml] and [res/layout] md5 from apk dir"
    else
        echocolor "$2: [res/xml] and [res/layout] don't exist file"
    fi
}

#字符串转十六进制
#str2hex "字符串"
function string2hex(){
    cd $CACHE
    local string2hex_mypython=$CACHE/mypython.py
    cat $PYTHONSCRIPT/string2hex.py | sed "s#StringConvertHex#$1#" >$string2hex_mypython
    python $string2hex_mypython
    [ -f $CACHE/file.txt ] && hex=`cat $CACHE/file.txt`
    echocolor "string2hex: Convert string[$1] to hex[$hex]"
    rm -f $CACHE/file.txt
    rm -f $string2hex_mypython
    cd ~
}

#字符串转十六进制
#hex2str "字符串"
function hex2string(){
    cd $CACHE
    hex2string_mypython=$CACHE/mypython.py
    cat $PYTHONSCRIPT/hex2string.py | sed "s#HexConvertString#$1#" >$hex2string_mypython
    python $hex2string_mypython
    [ -f $CACHE/file.txt ] && string=`cat $CACHE/file.txt`
    echocolor "string2hex: Convert hex[$1] to string[$string]"
    rm -f $CACHE/file.txt
    rm -f $hex2string_mypython
    cd ~
}

