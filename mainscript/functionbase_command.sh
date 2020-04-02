#!/system/bin/sh

##information of help
function functionbase_helpinfo(){
cat <<EOF

functionbase usage:
functionbase [--install | -i] [java | python | busybox | aria2c | all] [--cust | --miui]
              [--delete | -d] [java | python | busybox | aria2c | all]
              [--fix | -f]
              [--help | -h]

commands:
--install | -i :    [java | python | busybox | aria2c | all]
--delete | -d :    [java | python | busybox | aria2c | all]
--cust | --miui :    Install java and python environment to the cust block. if this command isn't exist, the environment will install to the '/data/local'.
--fix | -f :     Fix java or python configuration loss caused by reflashing packages or reboot device.Deservedly, You can copy the '.../Functionbase/build/fix_env.sh' shell script to the directory '/system/etc/init.d' etc.
--help | -h :   show the information of help.

EOF
}

##scriptfile path
if [ -n "${functionbase_commandfile}" ];then
    script_filepath=${functionbase_commandfile}
else
    echo -e "\nfunctionbase: Error, bin file is error.\nPlease rerun '.../FunctionbaseEnv/build/install_conf.sh'\n"
    functionbase_helpinfo
    exit 1
fi

##install busybox

export PATH=/system/xbin:/system/bin:/sbin/.magisk/busybox:$PATH

##path
env_dir=`dirname ${script_filepath} | sed 's#/mainscript$##' | sed 's#/toolfile/functionbase$##;s#^/sdcard#/data/media/0#;s#^/storage/self/primary#/data/media/0#;s#^/storage/emulated/0#/data/media/0#'`
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
    echo -e "functionbase: Error, '.../FunctionbaseEnv/mainscript/common_function.sh' don't exist"
    exit 1
fi
unmount_all
mount_all

#First tier commands
function functionbase(){
    case $1 in
        --install | -i )
            functionbase_install "$@";;
        --delete | -d )
            functionbase_delete "$@";;
        --fix | -f)
            functionbase_fix "$@";;
        --help | -h)
            functionbase_helpinfo;;
        *)
            echo -e "functionbase: Error, please print right command"
            functionbase_helpinfo;;
    esac;
}

#Second tier commands of --install
function functionbase_install(){
    case $2 in
        java)
            functionbase_install_java "$@";;
        python)
            functionbase_install_python "$@";;
        busybox)
            functionbase_install_busybox "$@";;
        aria2c)
            functionbase_install_aria2c "$@";;
        all)
            functionbase_install_all "$@";;
        *)
            echo -e "functionbase: Error, please print right command"
            functionbase_helpinfo;;
    esac;
}

#Third tier commands of install java
function functionbase_install_java(){
    check_command "functionbase" "3"
    case $3 in
        --cust | --miui)
            functionbase_install_java_start "$1" "$2" "/cust";;
        '')
            functionbase_install_java_start "$1" "$2" "/data/local";;
        *)
            echo -e "functionbase: Error, please print right command"
            functionbase_helpinfo;;
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

conf=\`grep "#java for functionbase" /system/etc/mkshrc\`
[ -n "\$conf" ] && sed -i "/#java for functionbase/,/#java for functionbase/d" /system/etc/mkshrc
java_home=${java_home}
java_conf_module >>/system/etc/mkshrc
ln -fs ${java_home}/bin/lib /lib
EOF
}

function env_jar_exist(){
    if [ -f ${env_tag_dir}/jar.tar.gz ] && [ -f ${env_tag_dir}/jdk.tar.gz ] && [ -f ${env_tag_dir}/jdklib.tar.gz ] && [ -f ${env_tag_dir}/python3.6.tar.gz ];then
        echo "functionbase: Ready release $1..."
    else
        echo "functionbase: Error, tag file don't exist"
        exit 1
    fi
}

function functionbase_install_java_start(){
    ##file check
    env_jar_exist "$2"
    if [ -f $3 ];then
        echo -e "functionbase: Error, $3 is a file, isn't a dir"
    else
        rm -rf $3/jdk
        tar -xzvf ${env_tag_dir}/jdk.tar.gz -C $3
        if [ -d $3/jdk ];then
            tar -xzvf ${env_tag_dir}/jar.tar.gz -C $3/jdk
        else
            echo "functionbase: Error, Release java fail"
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


function python_conf_module(){
cat <<EOF
#python for functionbase
export PATH=${python_home}/files/bin:\$PATH
#python for functionbase
EOF
}


function fix_python_module(){
cat << EOF

conf=\`grep "#python for functionbase" /system/etc/mkshrc\`
[ -n "\$conf" ] && sed -i "/#python for functionbase/,/#python for functionbase/d" /system/etc/mkshrc
python_home=${python_home}
python_conf_module >>/system/etc/mkshrc
EOF
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
    echo -e "functionbase: $1 installed successfully\nNow You can copy the '.../Functionbase/build/fix_env.sh' shell script to the directory '/system/etc/init.d' etc."
}

function functionbase_install_python_start(){
    env_jar_exist "$2"
    if [ -f $3 ];then
        echo -e "functionbase: Error, $3 is a file, isn't a dir"
    else
        ##add python env
        remove_java_python_flag "$2"
        rm -rf $3/python3.6
        tar -xzvf ${env_tag_dir}/python3.6.tar.gz -C $3
        python_home=$3/python3.6
        ##create java cache
        java_python_create_cache "$2"
        python_conf_module >>/system/etc/mkshrc
        ##create bin file
        mkdir -p ${env_dir}/tmp
        cp -af ${env_python_dir}/* ${env_dir}/tmp
        chmod -R "755" ${env_dir}/tmp/*
        sed -i "s#\[python_home\]#${python_home}#g" ${env_dir}/tmp/*
        cp -af ${env_dir}/tmp/* ${python_home}/files/bin
        rm -rf ${env_dir}/tmp
        setconf "Python_Home" "${python_home}" "$env_config_dir/FunctionbaseEnv.conf"
    fi
}


############
#install busybox
############
function functionbase_install_busybox(){
    check_command "functionbase" "2"
    check_busybox
    case $? in
        0)
            echo -e "functionbase: '/system/xbin/busybox' already installed";;
        1)
            install_busybox "${env_bin_dir}/busybox"
            echo -e "functionbase: '/system/xbin/busybox' installed successfully";;
        *)
            echo -e "functionbase: Error, `install_busybox` function is error";;
    esac;
}


############
#install aria2c
############
function functionbase_install_aria2c(){
    check_command "functionbase" "2"
    local tool=/system/bin/aria2c
    if [ ! -f $tool ];then
        cp -af ${env_bin_dir}/aria2c $tool
        chmod "755" $tool
        echo -e "functionbase: '$tool' installed successfuly"
    else
        echo -e "functionbase: '$tool' already installed"
    fi
}


############
#install all environment
############
function functionbase_install_all(){
    functionbase_install_java "$1" "java" "$3"
    functionbase_install_python "$1" "python" "$3"
    functionbase_install_busybox "$1" "busybox"
    functionbase_install_aria2c "$1" "aria2c"
    echo -e "functionbase: java python busybox aria2c installed successfully"
}



##Second commands of delete
function functionbase_delete(){
    case $2 in
        java)
            functionbase_delete_java "$@";;
        python)
            functionbase_delete_python "$@";;
        busybox)
            functionbase_delete_busybox "$@";;
        aria2c)
            functionbase_delete_aria2c "$@";;
	    all)
	        functionbase_delete_all "$@";;
        *)
            echo -e "functionbase: Error, please print right command"
            functionbase_helpinfo;;
    esac;
}


############
#delete java
############
#Third tier commands of delete java
function functionbase_delete_java(){
    check_command "functionbase" "2"
    getconf "Java_Home" "$env_config_dir/FunctionbaseEnv.conf"
    local conf=${conf_value}
    if [ -f $conf/bin/java ];then
        rm -rf $conf
        echo -e "functionbase: java deleted successfully"
    else
        echo -e "functionbase: java don't exist"
    fi
    rm -f ${env_cache_dir}/fix_java
    rm -f ${env_build_dir}/fix_env.sh
}


############
#delete python
############
#Third tier commands of delete python
function functionbase_delete_python(){
    check_command "functionbase" "2"
    getconf "Python_Home" "$env_config_dir/FunctionbaseEnv.conf"
    local conf=${conf_value}
    if [ -f $conf/files/bin/python ];then
        rm -rf $conf
        echo -e "functionbase: python deleted successfully"
    else
        echo -e "functionbase: python don't exist"
    fi
    rm -f ${env_cache_dir}/fix_python
    rm -f ${env_build_dir}/fix_env.sh
}


############
#delete busybox
############
function functionbase_delete_busybox(){
	check_command "functionbase" "2"
	delete_busybox "functionbase"
}


############
#delete aria2c
############
function functionbase_delete_aria2c(){
	check_command "functionbase" "2"
	local tool=/system/bin/aria2c
	if [ -f $tool ];then
		rm -f $tool
		return 0
	else
		echo "functionbase: '$tool' don't exist"
		return 1
	fi
}


############
#delete all
############
function functionbase_delete_all(){
	check_command "functionbase" "2"
	functionbase_delete_java "$@"
	functionbase_delete_python "$@"
	functionbase_delete_busybox "$@"
	functionbase_delete_aria2c "$@"
	echo -e "functionbase: java python busybox aria2c deleted successfully"
}



############
#fix 
############
function functionbase_fix(){
	check_command "functionbase" "1"
	local fix_file=${env_build_dir}/fix_env.sh
	if [ -f ${fix_file} ];then
		sh "${fix_file}"
		echo -e "functionbase: The environment fixed successfully"
	else
		echo -e "functionbase: '.../FunctionbaseEnv/build/fix_env.sh' file don't exist"
	fi
}


#Append cache
function functionbase_append_allcache(){
    local java_cache=${env_build_dir}/cache/fix_java
    local python_cache=${env_build_dir}/cache/fix_python
    if [ -f ${python_cache} ] && [ -f ${java_cache} ];then
        cat ${java_cache} ${python_cache} >${env_build_dir}/fix_env.sh
    elif [ ! -f ${python_cache} ] && [ -f ${java_cache} ];then
        mv -f ${java_cache} ${env_build_dir}/fix_env.sh
    elif [ -f ${python_cache} ] && [ ! -f ${java_cache} ];then
        mv -f ${python_cache} ${env_build_dir}/fix_env.sh
    else
        rm -f ${env_build_dir}/fix_env.sh
    fi
}


functionbase "$@"
functionbase_append_allcache
