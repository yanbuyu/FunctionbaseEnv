#!/system/bin/sh
# Copyright © 2020 yanbuyu's Open Source Project
##information of help
function env_setup_helpinfo(){
cat <<EOF

\033[36mfunctionbase usage:\033[0m
\033[33mfunctionbase [--install | -i] [jdk | python3.9.0 | python3.8.5 | all] <directory>
              [--delete | -d] [jdk | python | all] <directory>
              [--fix | -f]
              [--help | -h]

commands:
--install | -i :    Install jdk python3.9.0 python3.8.5 or all environment.
--delete | -d :    Deleted jdk python3.9.0 python3.8.5 or all environment.
--fix | -f :     Fix jdk or python configuration loss caused by reflashing packages or reboot device.Deservedly, You can copy the '.../Functionbase/build/fix_env.sh' shell script to the directory '/system/etc/init.d' etc.
--help | -h :   show the information of help.\033[0m

EOF
}

function env_setup_error_exit(){
	echo "env_setup: Error, please print right option"
	echo -e "`env_setup_helpinfo`"
	exit $1
}

#env_dir=`dirname ${script_filepath} | sed 's#/mainscript$##' | sed 's#/toolfile/functionbase$##;s#^/sdcard#/data/media/0#;s#^/storage/self/primary#/data/media/0#;s#^/storage/emulated/0#/data/media/0#'`
env_tag_dir=${env_dir}/tag
env_bin_dir=${env_dir}/bin
env_config_dir=${env_dir}/config
env_mainscript_dir=${env_dir}/mainscript
env_build_dir=${env_dir}/build

##load env
if [ -f ${env_mainscript_dir}/common_function.sh ];then
    . ${env_mainscript_dir}/common_function.sh
else
    echo -e "\033[36mfunctionbase:\033[0m \033[31mError, can't find [common_function.sh]\033[0m"
    exit 2
fi
unmount_all
mount_all

function env_jar_exist(){
    if [ -f ${env_tag_dir}/jar.tar.gz ] && [ -f ${env_tag_dir}/jdk.tar.gz ] && [ -f ${env_tag_dir}/jdklib.tar.gz ] && [ -f ${env_tag_dir}/python3.8.5.tar.gz ] && [ -f ${env_tag_dir}/python3.9.0.tar.gz ];then
        echo "env_setup: Ready release $1..."
    else
        echo "env_setup: Error, Can't find tag file"
        exit 3
    fi
}

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

function java_python_create_cache(){
    ##create cache
    mkdir -p ${env_build_dir}/cache
    echo -e "##$1 for functionbase" >${env_build_dir}/cache/fix_$1
    sed -n "/^function $1_conf_module(){/,/^}/p" ${env_mainscript_dir}/functionbase_command.sh >>${env_build_dir}/cache/fix_$1
    fix_$1_module >>${env_build_dir}/cache/fix_$1
    echo -e "##$1 for functionbase" >>${env_build_dir}/cache/fix_$1
    echo "functionbase: $1 installed successfully"
}

############
#install jdk
############
function env_setup_install_java(){
    tar -xzvf ${env_tag_dir}/jdk.tar.gz -C $3
    if [ -d $3/jdk ];then
        tar -xzvf ${env_tag_dir}/jar.tar.gz -C $3/jdk
    else
        echo "env_setup: Error, release jdk fail"
    fi
    ##add java env
    sed -i "/#java for functionbase/,/#java for functionbase/d" /system/etc/mkshrc
    java_home=$3/jdk
    java_conf_module >>/system/etc/mkshrc
    ln -fs ${java_home}/bin/lib /lib
    ##create java cache
    java_python_create_cache "java"
    setconf "Java_Home" "${java_home}" "$env_config_dir/FunctionbaseEnv.conf"
}

############
#install python
############
function env_setup_install_python(){
    ##add python env
    tar -xzvf ${env_tag_dir}/$2.tar.gz -C $3
    [ -f ${env_tag_dir}/$2_lib.tar.gz ] && tar -xzvf ${env_tag_dir}/$2_lib.tar.gz -C $3/$2
    python_home=$3/$2
    if [ -d $3/$2 ];then
        echo "functionbase: $2 installed successfully"
    else
        echo "env_setup: Error, release $2 fail"
        exit 4
    fi
    setconf "Python_Home" "${python_home}" "$env_config_dir/FunctionbaseEnv.conf"
}

############
#fix 
############
function env_setup_fix(){
	local fix_file=${env_build_dir}/fix_env.sh
	if [ -f ${fix_file} ];then
		sh "${fix_file}"
		echo "env_setup: The environment fixed successfully"
	else
		echo "functionbase: Can't find [fix_env.sh] file"
		exit 5
	fi
}

############
#delete 
############
function env_setup_delete_env(){
    rm -rf $3/$2
    echo "env_setup: Deleted $2"
}

function env_setup_delete(){
    if [ ! "$2" == "all" ];then
        [ ! -d $3/$2 ] && echo "env_setup: Error, out directory don't exist" && return 7
    fi
    case $2 in
        'jdk')
            env_setup_delete_env "$@";;
        'python3.9.0')
            env_setup_delete_env "$@";;
        'python3.8.5')
            env_setup_delete_env "$@";;
        'all')
            env_setup_delete_env "$1" "jdk" "$3"
            env_setup_delete_env "$1" "python3.9.0" "$3"
            env_setup_delete_env "$1" "python3.8.5" "$3"
            ;;
        *)
            env_setup_error_exit 8;;
    esac
}

############
#istall
############
function env_setup_install(){
    env_jar_exist
    if [ ! "$2" == "all" ];then
        mkdir -p $3/$2
        [ ! -d $3/$2 ] && echo "env_setup: Error, out directory don't exist" && exit 6
        rm -rf $3/$2
    fi
    case $2 in
        'jdk')
            env_setup_install_java "$@";;
        'python3.9.0')
            env_setup_install_python "$@";;
        'python3.8.5')
            env_setup_install_python "$@";;
        'all')
            env_setup_install_java "$1" "jdk" "$3"
            env_setup_install_python "$1" "python3.9.0" "$3"
            ;;
        *)
            env_setup_error_exit 3;;
    esac
    [ -f ${env_build_dir}/cache/fix_java ] && cp -af ${env_build_dir}/cache/fix_java ${env_build_dir}/fix_env.sh
}

function env_setup(){
    case $# in
        3)
            if [ "$1" == "--install" ] || [ "$1" == "-i" ];then
                env_setup_install "$@"
            elif [ "$1" == "--delete" ] || [ "$1" == "-d" ];then
                env_setup_delete "$@"
            else
                env_setup_error_exit 1
            fi;;
        1)
            if [ "$1" == "--fix" ] || [ "$1" == "-f" ];then
                env_setup_fix "$@"
            elif [ "$1" == "--help" ] || [ "$1" == "-h" ];then
                env_setup_error_exit
            fi;;
        *)
            env_setup_error_exit 2;;
    esac
}

