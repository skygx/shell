#!/usr/bin/env bash
#
# NGINX data collection script
#
# Copyright (C) Nginx, Inc.

renice 20 -p $$ &>/dev/null

shopt -s nullglob

export LC_ALL=C
export PATH=/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/sbin:/usr/local/bin

PACKAGE_NAME="support-pkg-$(date +%s)"

NGINX_OSS_AGENT_PATH="/var/log/nginx-agent"
NGINX_OSS_AGENT_CONFIG_PATH="/etc/nginx-agent"
NGINX_AGENT_PATH="/var/log/nginx-controller"
NGINX_AGENT_CONFIG_PATH="/etc/nginx-controller"
NGINX_NAP_PATH="/var/log/app_protect"
NGINX_NAP_CONFIG_PATH="/etc/app_protect"
NGINX_NAP_OPT_PATH="/opt/app_protect"
NGINX_MODULE_PATH="/usr/lib/nginx/modules"
NGINX_BINARY="/usr/sbin/nginx"

# These Global variable can be changed at runtime with args, see -h or --help
# shellcheck disable=SC2155
export OUTPUT_DIR="$(pwd | sed 's/^\(.*[^/]\)$/\1\//')"
export SCRIPT_DEBUG=false
export EXCLUDE_AGENT_CONFIG=false
export EXCLUDE_AGENT_LOGS=false
export EXCLUDE_NAP_CONFIG=false
export EXCLUDE_NAP_LOGS=false
export EXCLUDE_NGINX_LOGS=false
export EXCLUDE_NGINX_DATA=false
export EXCLUDE_NGINX_API=false
export NGINX_LOGS_PATH="/var/log/nginx"
export VMSTAT_PROFILE_INTERVAL_SEC=15

# Array of common NGINX services in systemd environments
SERVICES=(
    nginx
    nginx-debug
    nginx-agent
    nginx-app-protect
)

# Array of linux tools needed to run the script
DEPS=(
    egrep
    sed
    grep
    awk
    cat
    find
    ps
    cp
    tar
    file
)

SUPPORTED_MODULES=(
    libnginx-mod-http-geoip
    libnginx-mod-http-image-filter
    libnginx-mod-http-perl
    libnginx-mod-http-xslt-filter
    libnginx-mod-stream
    libnginx-mod-stream-geoip
    nginx-mod-http-geoip
    nginx-mod-http-image-filter
    nginx-mod-http-js
    nginx-mod-http-perl
    nginx-mod-http-xslt-filter
)

# HTTP Client
HTTP_CLIENT="curl"
HTTP_CLIENT_ARGS="-LksS"
HTTP_CLIENT_CONTENT_TYPE="-H Content-Type:application/json"
HTTP_CLIENT_TIMEOUT="--connect-timeout 5"

#
# Utility Functions
#

# Print messages in pretty colour
printc() {
    printf "\033[32m %b\033[0m" "$1"
}

# Print messages in red
printr() {
    printf "\033[31m %b\033[0m" "$1"
}

# Print messages in blue
printb() {
    printf "\033[34m %b\033[0m" "$1"
}

# Incompatible Input Validator
iiv() (
    all_cli_args="$1"
    input="$(echo "${all_cli_args}" | awk '{print $1;}')"
    for incompatible_input in "${@:2}"; do
        if [[ ${all_cli_args} == *"${incompatible_input}"* ]]; then
            print_error "Incompatible input ${incompatible_input} supplied with ${input}"
            exit 1
        fi
    done
)

# Simple Input Validator
siv() (
    name=$1
    value=$2
    check=$3

    if [[ ${value} == -* ]]; then
        print_error "Missing value for parameter ${name}"
        exit 1
    elif [[ -n "${check}" ]]; then
        if ! error=$("${check}" "${value}" 2>&1); then
            print_error "Parameter ${name} is invalid: ${error}"
            exit 1
        fi
    elif [[ -z "${value}" ]]; then
        print_error "Empty value for parameter ${name}"
        exit 1
    fi
)

print_phase() {
    printc "\n$*\n"
}

print_error() {
    printr "\n$*\n"
}

print_warn() {
    printb "\n$*\n"
}

sanitize_path() {
    echo "${1%/}"
}

create_path_if_not_exists() {
    if [[ ! -d "$1" ]]; then
        mkdir -p "$1"
    fi
}

copy_to_dir() {
    create_path_if_not_exists "$2"
    cp --no-dereference "$1"/* "$2" 2>/dev/null
}

copy_to_dir_recursive() {
    create_path_if_not_exists "$2"
    cp -r --no-dereference "$1"/. "$2"
}

copy_file_to_dir() {
    echo "Running command: [cp $1 $2]"
    eval cp --no-dereference "$1" "$2"
}

validate_argument() {
    if [[ -z "$2" ]]; then
        print_error "Argument $1 value empty"
        exit 1
    fi
}

fail_if_dir_not_exists() {
    if [[ ! -d "$1" ]]; then
        print_error "Directory $1 does not exist"
        exit 1
    fi
}

check_if_dir_exists() {
    if [[ ! -d "$1" ]]; then
        return 1
    fi
}

check_process_is_running() (
    if check_command "ps"; then
        pids=$(ps -o pid --no-headers -C "$1")
        if [[ -n "${pids}" ]]; then
            return 0
        fi
    fi
    return 1
)

is_compressed_file() (
  filename="$1"
  fileinfo=$(file --brief --mime-type "$filename")

  case "$fileinfo" in
    application/x-gzip|application/gzip|application/x-xz|application/x-bzip2|application/x-lzma|application/zip)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
)

is_not_empty() {
    if [[ -n "$1" ]]; then
        return 0
    fi
}

check_command() {
    if ! cmd=$(command -v "$1") || [[ ! -x "${cmd}" ]]; then
        return 1
    fi
    return 0
}

strip_password_lines() (
    filename=$1
    isDefault=${2:-true}
    line_count=0
    block_size=100
    newline=$'\n'

    # shellcheck disable=SC2001
    max_lines=$(sed 's/[[:space:]]//g' <<< "$(wc -l < "$filename")")
    tmpfile=$(mktemp /tmp/nginx-env.XXXXXX)

    while IFS=  read -r line; do
        line_count=$((line_count + 1))
        text="${text}${line}${newline}"
        if [ $((line_count % block_size)) -eq 0 ] || [ "$line_count" -eq "$max_lines" ]; then
            if [ "${isDefault}" == "true" ]; then
                # shellcheck disable=SC2001
                IFS=  sed 's/\"password\"[[:blank:]]*\:[[:blank:]]*\".*\"/##############/g' <<< "${text}" 2>&1 >> "${tmpfile}"
                text=""
            else
                # shellcheck disable=SC2001
                IFS=  sed 's/pass\(word\)\?\(_[0-9a-zA-Z]\+\)\?=[0-9a-zA-Z]\+/##############/gi' <<< "${text}" 2>&1 >> "${tmpfile}"
                text=""
            fi
        fi
    done < "$filename"
    mv "$tmpfile" "$filename"
)

is_ip_address() (
    ip=$1
    stat=1
    regexv6='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$'

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?

    elif [[ $ip =~ $regexv6 ]]; then
        stat=0
    fi
    return $stat
)

is_number() (
    number=$1
    if ! [[ ${number} =~ ^-?[0-9]+$ ]]; then
        return 1
    fi
    return 0
)

vm_arg_out_of_range() (
    arg=$1
    name=$2

    if ! [[ "${arg}" =~ ^[0-9]+$ ]];then
        print_warn "${name} ${arg} not an integer"
        exit 1
    fi

    if [[ "${arg}" -lt 1 ]] || [[ "${arg}" -gt 300 ]]; then
        print_warn "${name} out of range [1-30]"
        exit 1
    fi
)

## Functions ##

print_help() {
    echo "Usage: $0 [-option value...] "
    echo "  -h  | --help                    Print this help message"
    echo "  -d  | --debug                   Sets bash debug flag"
    echo "  -o  | --output_dir              Directory where support-pkg archive will be generated"
    echo "  -n  | --nginx_log_path          NGINX log directory path"
    echo "  -xc | --exclude_nginx_configs   Exclude all nginx configs from the support package"
    echo "  -xl | --exclude_nginx_logs      Exclude all nginx logs from the support package"
    echo "  -ac | --exclude_agent_configs   Exclude all agent configs from the support package"
    echo "  -al | --exclude_agent_logs      Exclude all agent logs from the support package"
    echo "  -nc | --exclude_nap_configs     Exclude all app protect configs from the support package"
    echo "  -nl | --exclude_nap_logs        Exclude all app protect logs from the support package"
    echo "  -ea | --exclude_api_stats       Exclude nginx plus api stats from the support package"
    echo "  -pi | --profile_interval        Profiling interval in seconds. Default: '15'"
}

get_base_nginx_conf() {
    config_files=(
        "/etc/nginx/nginx.conf"
        "/usr/local/nginx/conf/nginx.conf"
        "/usr/local/etc/nginx/nginx.conf"
    )

    nginx_base_config=$(ps -eo cmd,args | grep '[n]ginx -c' | sed 's/.*-c \([^ ]*\).*/\1/')

    if [ -z "$nginx_base_config" ]; then
        for config_file in "${config_files[@]}"; do
            if [ -e "$config_file" ]; then
                nginx_base_config="${config_file}"
                break
            fi
        done
    fi

    echo "${nginx_base_config}"
}

get_ethtool_info() {
  for dir in /sys/class/net/*/     # list directories in the form "/sys/class/net/dirname/"
  do
    dir=${dir%*/}      # remove the trailing "/"
    i="${dir##*/}"
    ethtool "${i}"
    echo "------";
  done
}

get_linux_host_info() (
    print_phase "Collecting system information"
    output_dir="$1"
    create_path_if_not_exists "${output_dir}"

    declare -A SYS_COMMANDS
    SYS_COMMANDS=(
        ["uname"]="uname -a"
        ["uname-short"]="uname -spr"
        ["release"]="find /etc -maxdepth 1 -name '*release' -print -exec cat {} \; -exec echo \;"
        ["lsb-release"]="lsb_release -a"
        ["free"]="free -m"
        ["ps"]="ps -eo uid,pid,ppid,c,sz,rss,psr,stime,tty,time,wchan:15,cmd,args"
        ["pstree"]="pstree"
        ["top-cpu"]="top -b -o +%CPU -n 3 -d 1 -w512 -c"
        ["top-mem"]="top -b -o +%MEM -n 3 -d 1 -w512 -c"
        ["df-i"]="df -i"
        ["df-h"]="df -h"
        ["env"]="env"
        ["locale"]="locale"
        ["lspci"]="lspci -vvv"
        ["swapon"]="swapon -s"
        ["sysctl"]="sysctl -a --ignore"
        ["selinux-mode"]="getenforce"
        ["netstat-nr"]="netstat -nr"
        ["ip-address"]="ip address"
        ["ip-route"]="ip route ls table all"
        ["ip-rule"]="ip rule"
        ["ip-neigh"]="ip neigh"
        ["resolvconf"]="cat /etc/resolv.conf"
        ["nsswitch"]="cat /etc/nsswitch.conf"
        ["fstab"]="cat /etc/fstab"
        ["hostsfile"]="cat /etc/hosts"
        ["proc-netstat"]="cat /proc/net/netstat"
        ["proc-sockstats"]="cat /proc/net/sockstat"
        ["proc-interrupts"]="cat /proc/net/interrupts"
        ["hostname"]="hostname"
        ["hostname-fqdn"]="hostname --fqdn"
        ["hostname-all-fqdns"]="hostname --all-fqdns"
        ["iptables-save"]="iptables-save"
        ["iptables-filter"]="iptables -L -n -v"
        ["iptables-nat"]="iptables -L -n -v -t nat"
        ["iptables-mangle"]="iptables -L -n -v -t mangle"
        ["iptables-raw"]="iptables -L -n -v -t raw"
        ["iptables-security"]="iptables -L -n -v -t security"
        ["firewall-cmd"]="firewall-cmd --list-all"
        ["ss-ltunp"]="ss -ltunp"
        ["ss-x"]="ss -x"
        ["ss-otn"]="ss -otn"
        ["uptime"]="uptime"
        ["cpuinfo"]="cat /proc/cpuinfo"
        ["meminfo"]="cat /proc/meminfo"
        ["vmstat"]="cat /proc/vmstat"
        ["mounts"]="cat /proc/mounts"
        ["swaps"]="cat /proc/swaps"
        ["lsmod"]="lsmod"
        ["systemd"]="journalctl -q --utc -n 10000"
        ["dmesg"]="dmesg -x -e"
        ["lsof"]="lsof -n"
        ["file-list"]="find / -mount -type f -path '*/nginx/*' -ls"
    )

    for name in "${!SYS_COMMANDS[@]}"; do
        cmd=${SYS_COMMANDS[${name}]}
        echo "Running command: [${cmd}]"
        # shellcheck disable=SC2086
        eval "${cmd} &> \"${output_dir}/${name}.txt\"" || :

        if [[ -f "${output_dir}/${name}.txt" ]] && [[ "${name}" == "systemd" ]]; then
          strip_password_lines "${output_dir}/${name}.txt"
        fi

        if [[ -f "${output_dir}/${name}.txt" ]] && [[ "${name}" == "selinux-mode" ]]; then
          if ! check_command "${cmd}"; then
            echo "Disabled" >"${output_dir}/${name}.txt" || :
          fi
        fi

    done

    # Handle more complex cases
    get_ethtool_info &>> "${output_dir}/ethtool.txt"

    # create a list of nginx files and checksums. This does not include the content of the files
    cmd=$(find / -name "nginx*" -type f -print 2>/dev/null)
    while IFS= read -r line; do
        if check_command "cksum"; then
            cksum "${line}" >> "${output_dir}/nginx-checksums.txt"
        fi
    done <<< "${cmd}"

    # vmstat profiling
    if check_command "timeout" && check_command "vmstat"; then
        print_warn "Running vmstat profiling for ${VMSTAT_PROFILE_INTERVAL_SEC} seconds..please wait"
        timeout "${VMSTAT_PROFILE_INTERVAL_SEC}" vmstat -w 1 >> "${output_dir}/vmstate_profiling.txt"
    fi

)

get_service_information() (
    print_phase "Collect service information"
    service_info_dir="${PACKAGE_DIR}/service-information"
    create_path_if_not_exists "${service_info_dir}"

    for svc in "${SERVICES[@]}"; do

        declare -A UNIT_SYS_COMMANDS
        UNIT_SYS_COMMANDS=(
            ["journalctl"]="journalctl -u ${svc} -r -n 10000"
            ["systemd"]="systemctl status ${svc}"
        )

        for name in "${!UNIT_SYS_COMMANDS[@]}"; do
            cmd=${UNIT_SYS_COMMANDS[${name}]}
            echo "Running command: [${cmd}]"
            target_file="${service_info_dir}/${svc}-${name}.txt"
            create_path_if_not_exists "${target_file%/*}" && touch "${target_file}"

            # shellcheck disable=SC2086
            ${cmd} > "${target_file}" 2>&1
        done
    done
)

get_nginx_process_info() (
    print_phase "Collecting nginx process information"
    output_dir="$1"
    package_name="nginx"

    create_path_if_not_exists "${output_dir}"

    if check_process_is_running "nginx"; then
        declare -A NGINX_COMMANDS
        NGINX_COMMANDS=(
            ["nginx-v"]="nginx -v"
            ["nginx-V"]="nginx -V"
        )

        for name in "${!NGINX_COMMANDS[@]}"; do
            cmd=${NGINX_COMMANDS[${name}]}
            echo "Running command: [${cmd}]"
            # shellcheck disable=SC2086
            ${cmd} >>"${output_dir}/${name}.txt" 2>&1
        done
    fi

    # determine dynamically linked libs that the nginx binary and modules are using
    if check_command "ldd"; then
        nginx_path=$(which nginx)
        if is_not_empty "${nginx_path}"; then
            echo "Running command: [ldd ${nginx_path}]"
            ldd "${nginx_path}" >>"${output_dir}/ldd-nginx.txt" 2>&1
        fi

        mapfile -t module_array < <(ls "${NGINX_MODULE_PATH}")
        for m in "${module_array[@]}"; do
            module_path="${NGINX_MODULE_PATH}/${m}"
            echo "Running command: [ldd ${module_path}]"
            ldd "${module_path}" >>"${output_dir}/ldd-${m}.txt" 2>&1
        done
    fi

    # analyze nginx master and workers memory map
    if check_process_is_running "nginx"; then
        cmd=$(ps -o pid --no-headers -C nginx)
        while IFS=" " read -r line; do
            echo "Running command: [pmap -X -p ${line}]"
            pmap -X -p "${line}" &>>"${output_dir}/pmap-nginx-pid-${line}.txt" 2>&1
        done <<< "${cmd}"
    fi

  # Query package manager (if it's being used)
    if [ -f /etc/debian_version ]; then
      distro="debian"
    else
      distro=$(cat /etc/*-release | grep ID_LIKE | sed -E 's/"|(ID_LIKE=)//g')
    fi

    case $distro in
        "debian|ubuntu" )
            if check_command "apt"; then
                dpkg -l | grep ${package_name} >>"${output_dir}/package-manager.txt" 2>&1
            fi
            ;;
        "rhel fedora" | "fedora" | "centos rhel fedora" | "amzn")
            if check_command "yum"; then
                yum list installed | grep ${package_name} >>"${output_dir}/package-manager.txt" 2>&1
            fi
            ;;
        "alpine" )
            if check_command "apk"; then
                apk list ${package_name} | grep 'installed' >>"${output_dir}/package-manager.txt" 2>&1
            fi
            ;;
        *)
            ;;
    esac
)

get_module_list() (
    nginx_base_config="$(get_base_nginx_conf)"

    test -z "${nginx_base_config}" && return
    prefix=`nginx -V 2>&1| grep ^configure | tr ' ' '\n' |
        awk -F= '/--prefix/ {print $2;}'`

    while read -r m
    do
        module=`readlink -f $m`
        if [ -z "$module" ]; then
            module=`readlink -f $prefix/$m`
        fi

        if [ -z $modules ];then
            modules="$module"
        else
            modules="$modules $module"
        fi
    done < <(cat $nginx_base_config |
        sed 's/^[[:space:]]*//;s/#.*$//' |
        tr -d '\n' |
        sed -e 's/http[[:space:]]*{.*//'|
        sed 's/;/;\n/g'|
        awk  '/load_module/ {print $2;}'|
        sed 's/;//')

    echo $modules
)

print_package_info() (
    output_dir="$1"
    if [ -n "${PRINT_SUPPORT_INFO}" ]; then
	echo $2
	echo
    else
	echo $2 >>"${output_dir}/package-info.txt"
	echo >> "${output_dir}/package-info.txt"
    fi
)

get_nginx_package_info() (
    print_phase "Collecting nginx package information"
    output_dir="$1"
    is_supported=1
    test -z "${PRINT_SUPPORT_INFO}" && create_path_if_not_exists "${output_dir}"

    if [ -f /etc/debian_version ]; then
      distro="debian"
    else
      distro=$(cat /etc/*-release | grep ID_LIKE | sed -E 's/"|(ID_LIKE=)//g')
    fi

    modules="$(get_module_list)"

    if [ -z "$modules" ]; then
        binaries="$NGINX_BINARY"
    else
        printf -v binaries "$NGINX_BINARY $modules"
    fi

    case $distro in
        "debian" | "ubuntu" )
            if check_command "apt"; then
                if ! dpkg -S $NGINX_BINARY >/dev/null 2>&1; then
                    print_package_info "${output_dir}" "No package for $NGINX_BINARY found"
                    test -z "${PRINT_SUPPORT_INFO}" && test -f $NGINX_BINARY && md5sum $NGINX_BINARY >>"${output_dir}/package-info.txt" 2>&1
                    return
                fi

                for b in $binaries
                do
                    package=`dpkg -S $b | awk -F: '{print $1}'`
                    maintainer=`dpkg -s $package |grep  ^Maintainer | sed -E 's/.*<(.*)>.*/\1/'`

                    case "$maintainer" in
                      "nginx-packaging@f5.com")
                        print_package_info "${output_dir}" "package $package has been built by NGINX"
                        ;;
                      "pkg-nginx-maintainers@alioth-lists.debian.net")
                        # Native Debian package
                        print_package_info "${output_dir}" "package $package has been built by Debian team"

                        if [ "$b" != "$NGINX_BINARY" ]; then
			    if [[ ! "${SUPPORTED_MODULES[*]}" =~ ${package} ]]; then
			        is_supported=0
			    fi
			fi
                        ;;
                      "ubuntu-devel-discuss@lists.ubuntu.com")
                        # Native Ubuntu package
                        print_package_info "${output_dir}" "package $package has been built by Ubuntu team"

                        if [ "$b" != "$NGINX_BINARY" ]; then
			    if [[ ! "${SUPPORTED_MODULES[*]}" =~ ${package} ]]; then
			        is_supported=0
			    fi
			fi
                        ;;
                      *)
                        is_supported=0
                        print_package_info "${output_dir}" "package $package has been built by $maintainer"
                    esac

                    test -z "${PRINT_SUPPORT_INFO}" && dpkg -s $package >>"${output_dir}/package-info.txt" 2>&1
                    test -z "${PRINT_SUPPORT_INFO}" && md5sum $b >>"${output_dir}/package-info.txt" 2>&1
                done
            fi
            ;;
        "rhel fedora" | "fedora" | "centos rhel fedora" | "amzn")
            if check_command "yum"; then
                if ! rpm -qf  $NGINX_BINARY >/dev/null 2>&1; then
                    print_package_info "${output_dir}" "No package for $NGINX_BINARY found"
                    test -z "${PRINT_SUPPORT_INFO}" && test -f $NGINX_BINARY && md5sum $NGINX_BINARY >>"${output_dir}/package-info.txt" 2>&1
                    return
                fi

                for b in $binaries
                do
                    package=`rpm -qf $b --queryformat '%{NAME}'`
                    maintainer=`rpm -qi $package | grep ^Vendor | sed 's/^.*: *//'`

                    case "$maintainer" in
                      "NGINX Packaging <nginx-packaging@f5.com>")
                        print_package_info "${output_dir}" "Package $package has been built by NGINX"
                        ;;
                      "Red Hat, Inc.")
                        print_package_info "${output_dir}" "Package $package has been built by Red Hat"
                        ;;
                      *)
                        print_package_info "${output_dir}" "Package $package has been built by unsupported maintainer $maintainer"
                        is_supported=0
                        ;;
                    esac

                    test -z "${PRINT_SUPPORT_INFO}" && rpm -qi $package >>"${output_dir}/package-info.txt" 2>&1
                    test -z "${PRINT_SUPPORT_INFO}" && md5sum $b >>"${output_dir}/package-info.txt" 2>&1
                done
            fi
            ;;
        "alpine" )
            if check_command "apk"; then
                if ! apk info -W $NGINX_BINARY >/dev/null 2>&1; then
                    print_package_info "${output_dir}" "No package for $NGINX_BINARY found"
                    test -z "${PRINT_SUPPORT_INFO}" && test -f $NGINX_BINARY && md5sum $NGINX_BINARY >>"${output_dir}/package-info.txt" 2>&1
                    return
                fi

                for b in $binaries
                do
                    package=`apk info -W $NGINX_BINARY | sed -E 's/.*owned by (.*)-\d.*/\1/'`
                    maintainer=`sed -n "/P:$package\$/,/^\$/p" /lib/apk/db/installed|grep ^m:| sed -E 's/.*<(.*)>.*/\1/'`

                    case "$maintainer" in
                      "nginx-packaging@f5.com")
                        print_package_info "${output_dir}" "Package $package has been built by NGINX"
                        ;;
                      "jakub@jirutka.cz")
                        print_package_info "${output_dir}" "Package $package has been built by Alpine maintaner"
                        if [ "$b" != "$NGINX_BINARY" ]; then
			    if [[ ! "${SUPPORTED_MODULES[*]}" =~ ${package} ]]; then
			        is_supported=0
			    fi
			fi
                        ;;
                      *)
                        print_package_info "${output_dir}" "Package $package has been built by unsupported maintainer $maintainer"
                        is_supported=0
                        ;;
                    esac

                    test -z "${PRINT_SUPPORT_INFO}" && sed -n "/P:$package\$/,/^\$/p" /lib/apk/db/installed >>"${output_dir}/package-info.txt" 2>&1
                    test -z "${PRINT_SUPPORT_INFO}" && md5sum $NGINX_BINARY >>"${output_dir}/package-info.txt" 2>&1
                done
            fi
            ;;
        *)
            ;;
    esac

    if [ $is_supported -eq 1 ]; then
       echo "Current nginx config is supported"
       test -z "${PRINT_SUPPORT_INFO}" && sed -i '1s/^/Current nginx config IS supported\n\n/' ${output_dir}/package-info.txt
    else
       echo "Current nginx config IS NOT supported"
       test -z "${PRINT_SUPPORT_INFO}" && sed -i '1s/^/Current nginx config IS NOT supported\n\n/' ${output_dir}/package-info.txt
    fi
)

get_nginx_running_configs_and_scripts() (
    output_dir="$1"
    create_path_if_not_exists "${output_dir}"

    # Using an array allows for future commands to be added
    declare -A NGINX_COMMANDS
    NGINX_COMMANDS=(
        ["nginx-T"]="nginx -T"
    )

    for name in "${!NGINX_COMMANDS[@]}"; do
        cmd=${NGINX_COMMANDS[${name}]}
        echo "Running command: [${cmd}]"
        # shellcheck disable=SC2086
        ${cmd} >>"${output_dir}/${name}.txt" 2>&1
    done

    # Create a directory for the raw files
    create_path_if_not_exists "${output_dir}/configs"

    # Extract nginx base config file from ps
    nginx_base_config="$(get_base_nginx_conf)"
    nginx_base_path="${nginx_base_config%/*}"
    nginx_conf_file="${nginx_base_config##*/}"
    copy_file_to_dir "${nginx_base_config}" "${output_dir}/configs/${nginx_conf_file}"

    # Extract and copy files in include directives
    cmd=$(cat "$nginx_base_config" | grep include | awk '{$1=$1};1' | tr -s ' ' | awk -F'[; ]' '{print $2;}')

    # The length of string is zero. No includes.
    if [[ -z "${cmd}" ]]; then
        return
    fi

    while IFS= read -r line; do
        if is_not_empty "${line}"; then
            if [[ ${line} != *"/"* ]]; then
                copy_file_to_dir "${nginx_base_path}/${line}" "${output_dir}/configs/"
            else
                copy_file_to_dir "${line}" "${output_dir}/configs/"
            fi
        fi
    done <<< "${cmd}"
)

is_absolute_path() (
    filename=$1
    if [[ "${filename}" = /* ]]; then
        return 0
    else
        return 1
    fi
)

get_nginx_logs() (
    print_phase "Collecting nginx access and error logs"
    create_path_if_not_exists "${PACKAGE_DIR}/nginx-logs/"

    nginx_base_config="$(get_base_nginx_conf)"

    # Get the nginx prefix from the output of nginx -V
    prefix=$(nginx -V 2>&1 | tr ' ' '\n' | grep '\-\-prefix' | awk -F '=' '{print $2}')

    # gather all the log paths filtering out access_log off, # access_log
    log_paths=$(cat "$nginx_base_config" | grep '^[[:blank:]]*access_log' | grep -v '^[[:blank:]]*access_log.*off' | awk '{$1=$1};1' | tr -s ' ' | awk -F'[; ]' '{print $2;}')

    # Default the log path if there are access_log directives
    if [[ "${log_paths}" == "" ]]; then
        log_paths="${NGINX_LOGS_PATH}/access.log}"
    fi

    # Convert the log paths into an array for efficient operation
    eval "arr=($log_paths)"

    # Get the unique paths i.e. remove duplicate paths for efficiency
    declare -A uniq_paths
    for path in "${arr[@]}"; do
        uniq_paths[$path]=0
    done

    for path in "${!uniq_paths[@]}"; do
        log_folder=$(dirname "${path}")
        if is_absolute_path "${log_folder}"; then
            absolute_path="${log_folder}"
        else
            absolute_path="${prefix}/${log_folder}"
        fi

        echo "Copying nginx log files from ${absolute_path}"
        for file in "${absolute_path}"/*; do
            [[ -e "${file}" ]] || break
            if ! is_compressed_file "${file}"; then
                create_path_if_not_exists "${PACKAGE_DIR}/nginx-logs/${absolute_path}"
                copy_file_to_dir "${file}" "${PACKAGE_DIR}/nginx-logs/${file}"
            fi
        done
    done
)

get_agent_logs() (
    print_phase "Collecting agent logs"
    output_dir="$1"
    create_path_if_not_exists "${output_dir}"

    # NGINX Agent and NGINX Controller Agent Logs
    if check_if_dir_exists "${NGINX_OSS_AGENT_PATH}"; then
        echo "Copying agent log files from ${NGINX_OSS_AGENT_PATH}"
        copy_to_dir "${NGINX_OSS_AGENT_PATH}" "${output_dir}"
        return 0
    fi

    if check_if_dir_exists "${NGINX_AGENT_PATH}"; then
        echo "Copying agent log files from ${NGINX_AGENT_PATH}"
        copy_to_dir "${NGINX_AGENT_PATH}" "${output_dir}"
        return 0
    fi

    # Check if OSS Agent is running and started with a custom path --log-path
    if check_process_is_running "nginx-agent"; then
        pid=$(ps -o pid --no-headers -C nginx-agent | sed -e 's/^[ \t]*//' -e 's/\ *$//g')
        if is_not_empty "${pid}"; then
            # shellcheck disable=SC2312
            path=$(ps -o args= -p "${pid}" | awk -F '--log-path' '{print $2}' | xargs)
            if check_if_dir_exists "${NGINX_AGENT_PATH}"; then
                echo "Copying agent log files from ${path}"
                copy_to_dir "${path}" "${output_dir}"
            fi
        fi
    fi
)

get_agent_configs() (
    print_phase "Collecting agent configs"
    output_dir="$1"
    create_path_if_not_exists "${output_dir}"

    # NGINX Agent and NGINX Controller Agent Config Path
    if check_if_dir_exists "${NGINX_OSS_AGENT_CONFIG_PATH}"; then
        echo "Copying agent config files from ${NGINX_OSS_AGENT_CONFIG_PATH}"
        copy_to_dir "${NGINX_OSS_AGENT_CONFIG_PATH}" "${output_dir}"
        return 0
    fi

    if check_if_dir_exists "${NGINX_AGENT_CONFIG_PATH}"; then
        echo "Copying agent config files from ${NGINX_AGENT_CONFIG_PATH}"
        copy_to_dir "${NGINX_AGENT_CONFIG_PATH}" "${output_dir}"
        sed -i '/api_key/d' "${output_dir}/agent.conf" &>/dev/null
        return 0
    fi

    # Check if OSS Agent is running and started with a custom path --config-dirs
    if check_process_is_running "nginx-agent"; then

        pid=$(ps -o pid --no-headers -C nginx-agent | sed -e 's/^[ \t]*//' -e 's/\ *$//g')

        if is_not_empty "${pid}"; then
            # shellcheck disable=SC2312
            path=$(ps -o args= -p "${pid}" | awk -F '--config-dirs' '{print $2}' | xargs)
            if check_if_dir_exists "${path}"; then
                echo "Copying agent agent files from ${path}"
                copy_to_dir "${path}" "${output_dir}"
            fi
        fi
    fi
)

get_app_protect_logs() (
    print_phase "Collecting NGINX app protect logs"
    output_dir="$1"
    create_path_if_not_exists "${output_dir}"

    #Syntax: app_protect_security_log [LOG-CONFIG-FILE] [DESTINATION]

    # Check default log config files
    if check_if_dir_exists "${NGINX_NAP_PATH}"; then
        echo "Copying NGINX app protect log config files from ${NGINX_NAP_PATH}"
        copy_to_dir "${NGINX_NAP_PATH}" "${output_dir}"
    fi

    nginx -T >>"${output_dir}/nginx-app-protect-logs.tmp" 2>&1

    # Collect log config files from directive
    nap_log_configs=$(grep -w app_protect_security_log "${output_dir}/nginx-app-protect-logs.tmp" | sed 's/^[[:space:]]*//' | sed 's/.*"\(.*\)".*/\1/')

    # Collect the logs if the destination is a file
    nap_log_destinations=$(grep -w app_protect_security_log "${output_dir}/nginx-app-protect-logs.tmp" | sed 's/^[[:space:]]*//' | awk '{print $3}' | tr -d ';')

    # Remove temp file
    rm "${output_dir}/nginx-app-protect-logs.tmp"

    # The length of string is zero. No includes.
    if [[ -z "${nap_log_configs}" ]]; then
        return
    fi

    create_path_if_not_exists "${output_dir}/app_protect_log_configs"

    while IFS= read -r line; do
        if is_not_empty "${line}"; then
            copy_file_to_dir "${line}" "${output_dir}/app_protect_log_configs"
        fi
    done <<< "${nap_log_configs}"

    # The length of string is zero. No includes.
    if [[ -z "${nap_log_destinations}" ]]; then
        return
    fi

    create_path_if_not_exists "${output_dir}/app_protect_log_files"
    while IFS= read -r line; do
        if [[ -f "${line}" ]]; then
            copy_file_to_dir "${line}" "${output_dir}/app_protect_log_files"
        fi
    done <<< "${nap_log_destinations}"

)

get_app_protect_configs() (
    print_phase "Collecting NGINX app protect configs"
    output_dir="$1"
    database_path="${NGINX_NAP_OPT_PATH}"/db
    database_configs="${NGINX_NAP_OPT_PATH}"/bd_config

    create_path_if_not_exists "${output_dir}"

    # Collect bd_config
    if check_if_dir_exists "${NGINX_NAP_OPT_PATH}/bd_config"; then
        echo "Copying NGINX app protect bd configs"
        tar -czf "${output_dir}/bd_configs.tar.gz" -C "${NGINX_NAP_OPT_PATH}/bd_config" .
    fi

    # Collect app_protect databases
    if check_if_dir_exists "${NGINX_NAP_OPT_PATH}/db"; then
        echo "Copying NGINX app protect databases"
        for database in DCC PLC; do
            if [[ -f "${NGINX_NAP_OPT_PATH}/db/${database}" ]]; then
                tar -czf ${output_dir}/app_protect_db_${database}.tar.gz "${NGINX_NAP_OPT_PATH}/db/${database}" 2> /dev/null
            fi
        done
    fi

    # Collect NAP configs from default location
    if check_if_dir_exists "${NGINX_NAP_CONFIG_PATH}"; then
        echo "Copying NGINX app protect configs files from ${NGINX_NAP_CONFIG_PATH}"
        copy_to_dir_recursive "${NGINX_NAP_CONFIG_PATH}" "${output_dir}"
    fi

    # Collect policies
    nginx -T >>"${output_dir}/nginx-app-protect-configs.tmp" 2>&1
    policies=$(grep app_protect_policy_file "${output_dir}/nginx-app-protect-configs.tmp" | sed 's/.*"\(.*\)".*/\1/')

    # Remove temp file
    rm "${output_dir}/nginx-app-protect-configs.tmp"

    # The length of string is zero. No includes.
    if [[ -z "${policies}" ]]; then
        return
    fi

    create_path_if_not_exists "${output_dir}/app_protect_policies"

    while IFS= read -r line; do
        if is_not_empty "${line}"; then
            copy_file_to_dir "${line}" "${output_dir}/app_protect_policies"
        fi
    done <<< "${policies}"
)

get_app_protect_version() (
    print_phase "Collecting NGINX app protect version"

    if [[ -f "${NGINX_NAP_OPT_PATH}/VERSION" ]]; then
        # Query package manager
        if [[ -f /etc/debian_version ]]; then
            distro="debian"
        else
            distro=$(cat /etc/*-release | grep ID_LIKE | sed -E 's/"|(ID_LIKE=)//g')
        fi

        case ${distro} in
            "debian|ubuntu" )
                if check_command "apt"; then
                    apt list --installed app-protect >>"${output_dir}/nap-version.txt" 2>&1
                fi
                ;;
            "rhel fedora" | "fedora" | "centos rhel fedora" | "amzn")
                if check_command "rpm"; then
                    rpm -qa app-protect >>"${output_dir}/nap-version.txt" 2>&1
                fi
                ;;
            "alpine" )
                if check_command "apk"; then
                    apk list app-protect >>"${output_dir}/nap-version.txt" 2>&1
                fi
                ;;
            *)
                ;;
        esac
    fi
)

check_api_connectivity() (
    address="$1"
    port="$2"
    uri="$3"

    echo "Attempting to reach API on ${address}:${port}"

    status_code=$(eval "${HTTP_CLIENT}" "${HTTP_CLIENT_ARGS}" "${HTTP_CLIENT_TIMEOUT}" --write-out "%{http_code}" -o /dev/null "${address}":"${port}"/"${uri}")
    if [[ "${status_code}" -eq 401 ]] ; then
        print_error "NGINX Plus API authentication error"
            return 1
    fi

    if [[ "${status_code}" -ne 200 ]] ; then
        print_error "NGINX Plus API failed to query"
        return 1
    fi
    return 0
)

get_plus_api_stats() (
    address="$1"
    port="$2"
    api_location="$3"
    version="$4"
    output_dir="$5"

    create_path_if_not_exists "${output_dir}"

     # Endpoints listed http://nginx.org/en/docs/http/ngx_http_api_module.html#nginx
    declare -A NGINX_PLUS_API_ENDPOINTS
    NGINX_PLUS_API_ENDPOINTS=(
            ["versions"]=""
            ["nginx"]="nginx"
            ["connections"]="connections"
            ["slabs"]="slabs"
            ["http"]="http"
            ["http-requests"]="http/requests"
            ["http-server-zones"]="http/server_zones"
            ["http-location-zones"]="http/location_zones"
            ["http-caches"]="http/caches"
            ["http-limit_conns"]="http/limit_conns"
            ["http-limit_reqs"]="http/limit_reqs"
            ["http-upstreams"]="http/upstreams"
            ["http-keyvals"]="http/keyvals"
            ["stream"]="stream"
            ["stream-server-zones"]="stream/server_zones"
            ["stream-limit-conns"]="stream/limit_conns"
            ["stream-upstreams"]="stream/upstreams"
            ["stream-keyvals"]="stream/keyvals"
            ["stream-zone-sync"]="stream/zone_sync"
            ["resolvers"]="resolvers"
            ["ssl"]="ssl"
        )
    for endpoint in "${!NGINX_PLUS_API_ENDPOINTS[@]}"; do
        echo "Running command: curl ${address}:${port}${api_location}/${version}/${NGINX_PLUS_API_ENDPOINTS[${endpoint}]}"
        cmd="${HTTP_CLIENT} ${HTTP_CLIENT_ARGS} ${HTTP_CLIENT_CONTENT_TYPE} ${HTTP_CLIENT_TIMEOUT} $address:$port$api_location/$version/${NGINX_PLUS_API_ENDPOINTS[$endpoint]} -o ${output_dir}/$endpoint.txt"
        # shellcheck disable=SC2086
        ${cmd}
    done
)

get_plus_api_details() (
    print_phase "Collecting NGINX Plus stats"
    version=0
    output_dir="$1"
    create_path_if_not_exists "$output_dir"

    if ! check_command "curl"; then
        print_error "curl not available. Skipping stub and api data collection"
        return
    fi

    # Write temporary file with the result of nginx -T
    nginx -T >>"${output_dir}/nginx-configs.tmp" 2>&1

    # Check if the plus api is enabled
    api_list=$(cat "${output_dir}/nginx-configs.tmp" | awk '
	/^[[:blank:]]*#/ {next}
	/server_name/ {sn=$2}
	/listen/ {lsn=$2; ssl=0; if ($0 ~ "ssl") ssl=1;}
	/location/ {fl=1;location=$2;next}
	/}/ {fl=0;}
	/^ *api.*;/ {if(fl) print sn "\t" lsn "\t" location "\t" ssl; exit}' | tr -d \;)

    if is_not_empty "${api_list}"; then
        # Extract api location, server_name and listen directives from the api config block
	api_location=$(echo $api_list | cut -d' ' -f 3)
	server_name=$(echo $api_list | cut -d' ' -f 1)
	listen=$(echo $api_list | cut -d' ' -f 2)
	ssl=$(echo $api_list | cut -d' ' -f 4)

        # Remove the temporary file
        rm "${output_dir}/nginx-configs.tmp"

        # Infer address and port from the two directives above
        if [[ $listen == *":"* ]]; then
            address=$(echo "$listen" | cut -d':' -f1)
            port=$(echo "$listen" | cut -d':' -f2)
        else
            address=$server_name
            port=$listen
        fi

	if [[ $ssl -eq 1 ]]; then
	    address="https://$address"
	fi

        if ! check_api_connectivity "${address}" "${port}" "${api_location}"; then
            return
        fi

        # Detect highest supported api version
        api_version=$("${HTTP_CLIENT}" "${HTTP_CLIENT_ARGS}" ${HTTP_CLIENT_CONTENT_TYPE} ${HTTP_CLIENT_TIMEOUT} "${address}":"${port}${api_location}" | sed 's/[^0-9]*/ /g')
        IFS=' ' read -r -a verion_array <<< "$api_version"

        for v in "${verion_array[@]}"
        do
            if (( v > version )); then
                version=$v
            fi
        done

        get_plus_api_stats "$address" "$port" "$api_location" "$version" "$output_dir"
    fi
)

check_deps() (
    # Ensure script is running with sudo
    if [[ "${EUID}" -ne 0 ]]; then
        print_error "Please run $0 script as root"
        exit 1
    fi

    print_phase "Checking script dependencies"
    # Associative arrays were added in Bash 4
    if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]
    then
        print_error "Bash version 4 or higher is required to run this script"
        exit 1
    fi

    # Check dependency array
    for dep in "${DEPS[@]}"; do
        if ! check_command "${dep}"; then
            print_error "Cannot find ${dep} binary. Install ${dep} or add it to the the \$PATH."
            exit 1
        fi
    done
)

generate() (
    #
    # collect nginx log files
    #
    if ! ${EXCLUDE_NGINX_LOGS}; then
        get_nginx_logs
    else
        print_warn "Excluding nginx access and error logs"
    fi
    #
    # collect agent logs and configs (if they exist)
    #
    get_agent_info_dir="${PACKAGE_DIR}/agent"

    if ! ${EXCLUDE_AGENT_LOGS}; then
        get_agent_logs "${get_agent_info_dir}"
    else
        print_warn "Excluding agent logs"
    fi

    if ! ${EXCLUDE_AGENT_CONFIG}; then
        get_agent_configs "${get_agent_info_dir}"
    else
        print_warn "Excluding agent configs"
    fi

    #
    # collect *nix host commands
    #
    sys_info_dir="${PACKAGE_DIR}/system-information"
    create_path_if_not_exists "${sys_info_dir}"
    get_linux_host_info "${sys_info_dir}"

    #
    # collect nginx process information
    #
    get_nginx_process_info_dir="${PACKAGE_DIR}/nginx-information"
    create_path_if_not_exists "${get_nginx_process_info_dir}"
    get_nginx_process_info "${get_nginx_process_info_dir}"
    get_nginx_package_info "${get_nginx_process_info_dir}"

    #
    # collect nginx configs
    #
    if ! ${EXCLUDE_NGINX_DATA}; then
        get_nginx_running_configs_and_scripts "${get_nginx_process_info_dir}"
    else
      print_warn "Excluding nginx config files"
    fi

    #
    # Linux service information
    #
    get_service_information

    #
    # collect nginx app protect (WAF) information
    #
    get_nap_process_info_dir="${PACKAGE_DIR}/nginx-app-protect"
    create_path_if_not_exists "${get_nap_process_info_dir}"

    if ! ${EXCLUDE_NAP_LOGS}; then
        get_app_protect_logs "${get_nap_process_info_dir}"
    else
        print_warn "Excluding app protect logs"
    fi

    if ! ${EXCLUDE_NAP_CONFIG}; then
        get_app_protect_configs "${get_nap_process_info_dir}"
        get_app_protect_version "${get_nap_process_info_dir}"
    else
        print_warn "Excluding app protect configs and version"
    fi


    #
    # collect status from plus api
    #
    stats_info_dir="${PACKAGE_DIR}/api-stats"
    create_path_if_not_exists "${stats_info_dir}"
    if ! ${EXCLUDE_NGINX_API}; then
        get_plus_api_details "${stats_info_dir}"
    else
        print_warn "Excluding nginx plus api status"
    fi
)

cleanup_dir() {
    print_phase "Cleaning Up"

    echo "Unsetting exported environment variables"
    # Unset exported environment variables
    unset OUTPUT_DIR SCRIPT_DEBUG EXCLUDE_AGENT_CONFIG EXCLUDE_AGENT_LOGS EXCLUDE_NAP_CONFIG EXCLUDE_NAP_LOGS NGINX_LOGS_PATH \
    EXCLUDE_NGINX_LOGS EXCLUDE_NGINX_DATA EXCLUDE_NGINX_API VMSTAT_PROFILE_INTERVAL_SEC

    echo "Removing temp directory ${PACKAGE_DIR}"
    if [[ -d "$1" ]]; then rm -Rf "$1" >/dev/null; fi

    exit 0
}

#
# Main
#

# Command Line Arguments
while [[ "$1" != "" ]]; do
    param=$1
    case ${param} in
        -o | --output_dir )
            shift
            siv "${param}" "$1"
            OUTPUT_DIR=$1
            ;;
        -n | --nginx_log_path )
            shift
            siv "${param}" "$1"
            NGINX_LOGS_PATH=$1
            ;;
        -xl | --exclude_nginx_logs)
            EXCLUDE_NGINX_LOGS=true
            ;;
        -xc | --exclude_nginx_conf)
            EXCLUDE_NGINX_DATA=true
            ;;
        -ac | --exclude_agent_configs)
            EXCLUDE_AGENT_CONFIG=true
            ;;
        -al | --exclude_agent_logs)
            EXCLUDE_AGENT_LOGS=true
            ;;
        -nc | --exclude_nap_configs)
            EXCLUDE_NAP_CONFIG=true
            ;;
        -nl | --exclude_nap_logs)
            EXCLUDE_NAP_LOGS=true
            ;;
        -ea | --exclude_api_stats)
            EXCLUDE_NGINX_API=true
            ;;
        -pi | --profile_interval )
            shift
            vm_arg_out_of_range $1 '--profile_interval'
            VMSTAT_PROFILE_INTERVAL_SEC=$1
            ;;
        -h | --help)
            print_help
            exit 0
            ;;
        -d | --debug)
            SCRIPT_DEBUG=true
            ;;
        -s | --support)
            PRINT_SUPPORT_INFO=true
            ;;
        *)
            print_error "Unrecognized flag: $1"
            print_help
            exit 1
            ;;
    esac
    # shift to get next param name in $1
    shift
done

# Check linux tools required to run this script
check_deps

# Set bash debug logging
if ${SCRIPT_DEBUG}; then
    set -x
fi

if [ -n "${PRINT_SUPPORT_INFO}" ]; then
    get_nginx_package_info
    exit 0
fi
# Call main() in a subshell and capture stdout/stderr in a file to be included
# in the support package.

print_phase "Creating Directories"
PACKAGE_DIR="$(mktemp -d /tmp/nginx-sp-XXXXXX)"

# trap if the script receives a SIGINIT (Ctrl+C)
trap 'cleanup_dir "$PACKAGE_DIR"' SIGINT

if [[ $? -ne 0 ]]; then
    print_error "Unable to create temporary directory"
    exit 1
fi
echo "Using tmp directory: ${PACKAGE_DIR}"
(
    # shellcheck disable=SC2312
    generate "$@"
) 2>&1 | tee "${PACKAGE_DIR}/support-package.log"

# Generate archive
archive_file="${OUTPUT_DIR}${PACKAGE_NAME}.tar.gz"
tar -C "${PACKAGE_DIR}" -czf "${archive_file}" .

print_phase "Package output"
echo "Archive ${archive_file} ready"

# Clean up
cleanup_dir "${PACKAGE_DIR}"

shopt -u nullglob
