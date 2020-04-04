#!/system/bin/sh
# Copyright © 2020 yanbuyu's Open Source Project
##warnning: please run it by "sh" command.

function functionbase_bin_module(){
cat <<EOF
functionbase_commandfile=${env_dir}/mainscript/functionbase_command.sh
if [ -f \${functionbase_commandfile} ];then
    . \${functionbase_commandfile} "\$@"
else
    echo -e "\033[36minstallbin:\033[0m \033[31mError, Can't find the main script\033[0m"
    exit
fi
EOF
}

###path
env_dir=`cd $(dirname $0);pwd | sed 's#/mainscript$##;s#^/sdcard#/data/media/0#;s#^/storage/self/primary#/data/media/0#;s#^/storage/emulated/0#/data/media/0#'`
common_script=${env_dir}/mainscript/common_function.sh
if [ -f ${common_script} ];then
	. ${common_script}
else
	echocolor "install_bin: Can't find 'common_function.sh' script"
fi

unmount_all
mount_all

##install busybox
check_busybox
[ "$?" == "1" ] && install_busybox && echocolor "The 'FunctionbaseEnv' need busybox, the busybox installed successfully"
export PATH=/system/xbin:/system/bin:/sbin/.magisk/busybox:$PATH

###
setconf "FunctionbaseEnv_Home" "${env_dir}" "${env_dir}/config/FunctionbaseEnv.conf"
functionbase_bin_module >/system/bin/functionbase
chmod "777" /system/bin/functionbase

