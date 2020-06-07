#!/system/bin/sh
# Copyright © 2020 yanbuyu's Open Source Project

env_dir=`cd $(dirname $0);pwd | sed 's#/build$##'`
common_script=${env_dir}/mainscript/env_setup.sh
if [ -f ${common_script} ];then
    . ${common_script}
else
    echo -e  "\033[36mintall_env:\033[0m 033[31mError, can't find [env_setup.sh]\033[0m"
fi

##For example
env_setup -d all /cust
env_setup -i all /cust
