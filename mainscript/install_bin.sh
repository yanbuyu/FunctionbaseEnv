#!/system/bin
function functionbase_bin_module(){
cat <<EOF
functionbase_commandfile=${env_dir}/mainscript/functionbase_command.sh
if [ -f \${functionbase_commandfile} ];then
    . \${functionbase_commandfile} "\$@"
else
    echo "Error, the main script don't exist"
    exit
fi
EOF
}

###path
env_dir=`cd $(dirname $0);pwd | sed 's#/mainscript$##'`
common_script=${env_dir}/mainscript/common_function.sh
if [ -f ${common_script} ];then
	. ${common_script}
else
	echo -e "install_bin: 'common_function.sh' script don't exist"
fi

unmount_all
mount_all

##install busybox
check_busybox
[ "$?" == "1" ] && install_busybox && echo "The 'FunctionbaseEnv' need busybox,busybox install successfully"
export PATH=/system/xbin:/system/bin:/sbin/.magisk/busybox:$PATH

###
setconf "FunctionbaseEnv_Home" "${env_dir}" "${env_dir}/config/FunctionbaseEnv.conf"
functionbase_bin_module >/system/bin/functionbase
chmod "777" /system/bin/functionbase

