#!/system/bin/sh

env_dir=`cd $(dirname $0);pwd | sed 's#/build$##'`
common_script=${env_dir}/mainscript/install_bin.sh
if [ -f ${common_script} ];then
    sh ${common_script}
    echo -e "Success, please input \"functionbase -h\" see the help information"
else
    echo -e  "Error, '.../FunctionbaseEnv/mainscript/install_bin.sh' don't exist"
fi

##Fox example
functionbase -i all --cust
