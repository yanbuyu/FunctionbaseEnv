#!/system/bin/sh
# Copyright © 2020 yanbuyu's Open Source Project

env_dir=`cd $(dirname $0);pwd | sed 's#/build$##'`
common_script=${env_dir}/mainscript/install_bin.sh
if [ -f ${common_script} ];then
    sh ${common_script}
    echo -e "\033[36mintall_env:\033[0m 033[33mSuccess, please input \"functionbase -h\" see the help information\033[0m"
else
    echo -e  "\033[36mintall_env:\033[0m 033[31mError, can't find '.../FunctionbaseEnv/mainscript/install_bin.sh'\033[0m"
fi

##For example
functionbase -i all --cust
