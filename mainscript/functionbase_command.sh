#!/system/bin/sh
# Copyright © 2020 yanbuyu's Open Source Project
##information of help
function functionbase_helpinfo(){
cat <<EOF

\033[36mfunctionbase usage:\033[0m
\033[33mfunctionbase [--install | -i] [java | python3.8.5 | python3.9.0 | all] <directory>
              [--delete | -d] [java | python | all] <directory>
              [--fix | -f]
              [--help | -h]

commands:
--install | -i :    Install java python3.7 python3.8.2 or all environment.
--delete | -d :    Deleted java python3.7 python3.8.2 or all environment.
--cust | --miui :    Install java and python environment to the cust block. if can't find this command, the environment will install to the '/data/local'.
--fix | -f :     Fix java or python configuration loss caused by reflashing packages or reboot device.Deservedly, You can copy the '.../Functionbase/build/fix_env.sh' shell script to the directory '/system/etc/init.d' etc.
--help | -h :   show the information of help.\033[0m

EOF
}

##epxport path
export PATH=/system/xbin:/system/bin:/sbin/.magisk/busybox:$PATH

##path
#env_dir=`dirname ${script_filepath} | sed 's#/mainscript$##' | sed 's#/toolfile/functionbase$##;s#^/sdcard#/data/media/0#;s#^/storage/self/primary#/data/media/0#;s#^/storage/emulated/0#/data/media/0#'`
env_tag_dir=${env_dir}/tag
env_bin_dir=${env_dir}/bin
env_config_dir=${env_dir}/config
env_mainscript_dir=${env_dir}/mainscript
env_build_dir=${env_dir}/build
env_python_dir=${env_dir}/python
env_cache_dir=${env_dir}/python

##load env
if [ -f ${env_mainscript_dir}/common_function.sh ];then
    . ${env_mainscript_dir}/common_function.sh
else
    echo -e "\033[36mfunctionbase:\033[0m \033[31mError, can't find '.../FunctionbaseEnv/mainscript/common_function.sh'\033[0m"
    exit 2
fi
unmount_all
mount_all

#First tier commands
function functionbase(){
    case $1 in
        '--install' | '-i' )
            functionbase_install "$@";;
        '--delete' | '-d' )
            functionbase_delete "$@";;
        '--fix' | '-f')
            functionbase_fix "$@";;
        '--help' | '-h')
            echo -e "`functionbase_helpinfo`";;
        *)
            echocolor "functionbase: Error, please print right command"
            echo -e "`functionbase_helpinfo`";;
    esac;
}

#Second tier commands of --install
function functionbase_install(){
    case $2 in
        java)
            functionbase_install_java "$@";;
        python)
            functionbase_install_python "$@";;
        all)
            functionbase_install_all "$@";;
        *)
            echocolor "functionbase: Error, please print right command"
            echo -e "`functionbase_helpinfo`";;
    esac;
}

#Third tier commands of install java
function functionbase_install_java(){
    check_command "functionbase" "$#" "3"
    case $3 in
        '--cust' | '--miui')
            functionbase_install_java_start "$1" "$2" "/cust";;
        '')
            functionbase_install_java_start "$1" "$2" "/data/local";;
        *)
            echocolor "functionbase: Error, please print right command"
            echo -e "`functionbase_helpinfo`";;
    esac;
}


############
#install java
############
function java_conf_module(){
cat <<EOF
#java for functionbase
export JAVA_HOME=${java_home}
export PATH=\$JAVA_HOME/bin:\$PATH
export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar
export JRE_HOME=\$JAVA_HOME/jre
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/lib
#java for functionbase
EOF
}

function fix_java_module(){
cat << EOF
mount -o rw,remount / 2>/dev/null;
mount -o rw,remount /data 2>/dev/null;
mount -o rw,remount /cust 2>/dev/null;
conf=\`grep "#java for functionbase" /system/etc/mkshrc\`
[ -n "\$conf" ] && sed -i "/#java for functionbase/,/#java for functionbase/d" /system/etc/mkshrc
java_home=${java_home}
java_conf_module >>/system/etc/mkshrc
ln -fs ${java_home}/bin/lib /lib
EOF
}

function env_jar_exist(){
    if [ -f ${env_tag_dir}/jar.tar.gz ] && [ -f ${env_tag_dir}/jdk.tar.gz ] && [ -f ${env_tag_dir}/jdklib.tar.gz ] && [ -f ${env_tag_dir}/python3.8.2.tar.gz ];then
        echocolor "functionbase: Ready release $1..."
    else
        echocolor "functionbase: Error, Can't find tag file"
        exit 3
    fi
}

function functionbase_install_java_start(){
    ##file check
    env_jar_exist "$2"
    if [ -f $3 ];then
        echocolor "functionbase: Error, $3 is a file, isn't a dir"
    else
        rm -rf $3/jdk
        tar -xzvf ${env_tag_dir}/jdk.tar.gz -C $3
        if [ -d $3/jdk ];then
            tar -xzvf ${env_tag_dir}/jar.tar.gz -C $3/jdk
        else
            echocolor "functionbase: Error, Release java fail"
        fi
    fi
    ##add java env
    remove_java_python_flag "$2"
    java_home=$3/jdk
    java_conf_module >>/system/etc/mkshrc
    ln -fs ${java_home}/bin/lib /lib
    ##create java cache
    java_python_create_cache "$2"
    setconf "Java_Home" "${java_home}" "$env_config_dir/FunctionbaseEnv.conf"
}


############
#install python
############
function functionbase_install_python(){
    case $3 in
        --cust | --miui)
            functionbase_install_python_start "$1" "$2" "/cust";;
        *)
            functionbase_install_python_start "$1" "$2" "/data/local";;
    esac;
}

function remove_java_python_flag(){
    local conf=`grep "#$1 for functionbase" /system/etc/mkshrc`
    [ -n "$conf" ] && sed -i "/#$1 for functionbase/,/#$1 for functionbase/d" /system/etc/mkshrc
}

function java_python_create_cache(){
    ##create cache
    mkdir -p ${env_build_dir}/cache
    echo -e "##$1 for functionbase" >${env_build_dir}/cache/fix_$1
    sed -n "/^function $1_conf_module(){/,/^}/p" ${env_mainscript_dir}/functionbase_command.sh >>${env_build_dir}/cache/fix_$1
    fix_$1_module >>${env_build_dir}/cache/fix_$1
    echo -e "##$1 for functionbase" >>${env_build_dir}/cache/fix_$1
    echocolor "functionbase: $1 installed successfully\nNow You can copy the '.../Functionbase/build/fix_env.sh' shell script to the directory '/system/etc/init.d' etc."
}

function functionbase_install_python_start(){
    env_jar_exist "$2"
    if [ -f $3 ];then
        echo -e "functionbase: Error, $3 is a file, isn't a dir"
    else
        ##add python env
        rm -rf $3/python3.8.2
        tar -xzvf ${env_tag_dir}/python3.8.2.tar.gz -C $3
        tar -xzvf ${env_tag_dir}/python3.8.2_lib.tar.gz -C $3/python3.8.2
        python_home=$3/python3.8.2
        setconf "Python_Home" "${python_home}" "$env_config_dir/FunctionbaseEnv.conf"
    fi
}

############
#install all environment
############
function functionbase_install_all(){
    functionbase_install_java "$1" "java" "$3"
    functionbase_install_python "$1" "python" "$3"
    echocolor "functionbase: java python installed successfully"
}



##Second commands of delete
function functionbase_delete(){
    case $2 in
        java)
            functionbase_delete_java "$@";;
        python)
            functionbase_delete_python "$@";;
	    all)
	        functionbase_delete_all "$@";;
        *)
            echocolor "functionbase: Error, please print right command"
            echo -e "`functionbase_helpinfo`";;
    esac;
}


############
#delete java
############
#Third tier commands of delete java
function functionbase_delete_java(){
    check_command "functionbase" "$#" "2"
    getconf "Java_Home" "$env_config_dir/FunctionbaseEnv.conf"
    local conf=${conf_value}
    if [ -f $conf/bin/java ];then
        rm -rf $conf
        echocolor "functionbase: java deleted successfully"
    else
        echocolor "functionbase: java don't exist"
    fi
    rm -f ${env_cache_dir}/fix_java
    rm -f ${env_build_dir}/fix_env.sh
}


############
#delete python
############
#Third tier commands of delete python
function functionbase_delete_python(){
    check_command "functionbase" "$#" "2"
    getconf "Python_Home" "$env_config_dir/FunctionbaseEnv.conf"
    local conf=${conf_value}
    if [ -f $conf/files/bin/python ];then
        rm -rf $conf
        echocolor "functionbase: python deleted successfully"
    else
        echocolor "functionbase: Can't find python"
    fi
    rm -f ${env_build_dir}/fix_env.sh
}


############
#delete all
############
function functionbase_delete_all(){
	check_command "functionbase" "$#" "2"
	functionbase_delete_java "$@"
	functionbase_delete_python "$@"
	echocolor "functionbase: java python deleted successfully"
}



############
#fix 
############
function functionbase_fix(){
	check_command "functionbase" "$#" "1"
	local fix_file=${env_build_dir}/fix_env.sh
	if [ -f ${fix_file} ];then
		sh "${fix_file}"
		echocolor "functionbase: The environment fixed successfully"
	else
		echocolor "functionbase: Can't find '.../FunctionbaseEnv/build/fix_env.sh' file"
		exit 5
	fi
}


#Append cache
function functionbase_append_allcache(){
    local java_cache=${env_build_dir}/cache/fix_java
    if [ -f ${java_cache} ];then
        mv -f ${java_cache} ${env_build_dir}/fix_env.sh
    else
        rm -f ${env_build_dir}/fix_env.sh
    fi
}


functionbase "$@"
functionbase_append_allcache
