#!/bin/bash -x

#
# Copyright 2021 HabanaLabs, Ltd.
# All Rights Reserved.
#
# Script based on https://github.com/HabanaAI/Setup_and_Install/README.md

#
# Requirements:
# Clean, updated OS installation
# User must have sudo access with no password
#
# Usage: sudo -E ./synapse_installation.sh [-h]
#   -h ............. Optional; show help

# OS support:
# - Ubuntu 18.04       Python3.8
# - Ubuntu 20.04       Python3.8
# - CentOS 7.8 and 8.3 Python3.8
# - Amazon Linux 2     Python3.8


#
# Habanalabs packages required
HABANALABS_REQUIRED="habanalabs-graph
                     habanalabs-thunk
                     habanalabs-firmware"
HABANALABS_OPTIONAL="habanalabs-firmware-tools
                     habanalabs-qual
                     habanalabs-aeon"
HABANALABS_COMMON="$HABANALABS_REQUIRED $HABANALABS_OPTIONAL"

#
# Temp filename
TMPF=/tmp/$0-$$.log


show_help()
{
    cat <<EOF
Usage: sudo -E ./synapse_installation.sh [-h]
   -h ............. Optional; show help

This script installs required OS packages and Habanalabs Gaudi drivers
Requirements:
Clean, updated OS installation
User must have sudo access with no password
OS support:
 - Ubuntu 18.04
 - Ubuntu 20.04
 - CentOS 7.8 and 8.3
 - Amazon Linux 2
EOF
}


#
# Parse options
while getopts h opt; do
    case $opt in
      h) show_help >&2; exit 1 ;;
      *) show_help >&2; exit 1 ;;
    esac
done
shift "$((OPTIND-1))" # Shift off the options and optional --.


#
# Returns true if the user has root privilege
is_root ()
{
    return $(id -u)
}


has_sudo()
{
    local prompt

    prompt=$(sudo -nv 2>&1)
    if [ $? -eq 0 ]; then
        echo "has_sudo__pass_set"
    elif grep -q '^sudo:' <<< $prompt; then
        echo "has_sudo__needs_pass"
    else
        echo "no_sudo"
    fi
}


#
# If an apt or yum operation is pending, wait for it to complete
# First argument is the required test
upd_ready()
{
    local upd_test=$1
    local sem=$(basename $(echo $upd_test|awk -F/ '{print $4}') .pid) # The "name" of the lock
    local WAIT_LOOP='
    i=0; tput sc 2>/dev/null||true;
    while X; do
        case $(($i % 4)) in 0) j="-";; 1) j="\\";; 2) j="|";; 3) j="/";; esac;
        tput rc 2>/dev/null||true;
        echo -en "\r[$j] Waiting for Y to free...";
        sleep 0.5; ((i=i+1));
    done'
    timeout 2m bash -c "$(sed -e "s,X,$upd_test,g" -e "s,Y,$sem,g" <<<$WAIT_LOOP)"
}


#
# Set number of huge pages
# Some training models use huge pages. It is recommended to set the number of huge pages as provided below:
set_huge_pages()
{
    # Calculate number of huge pages
    huge_pages_size=$(grep "^Hugepagesize:" /proc/meminfo | awk '{print $2}')
    huge_pages_memory=$((110 * 1024)) # convert to kB
    number_of_cores=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
    total_huge_pages_memory=$(($huge_pages_memory * $number_of_cores * 2))
    number_of_huge_pages=$(($total_huge_pages_memory / $huge_pages_size + 1))

    # Set current hugepages
    sysctl -w vm.nr_hugepages=$number_of_huge_pages
    # Remove old entry if exists in sysctl.conf
    sed --in-place '/nr_hugepages/d' /etc/sysctl.conf
    # Insert huge pages settings to persist
    echo "vm.nr_hugepages=$number_of_huge_pages" | tee -a /etc/sysctl.conf
}


#
# Return true/false if the drivers are installed
driver_install_check()
{
    if egrep -q "focal|bionic" <<<$DISTRIB_CODENAME; then
        # Ubuntu 18 or 20
        if dpkg -l | grep -q "habanalabs-firmware" &&
                dpkg -l | grep -q "habanalabs-dkms"; then
            return $(true)
        fi
    else
        # CentOS or Amazon Linux
        if rpm -qa | grep "habanalabs-firmware" &&
                rpm -qa | grep "habanalabs-[0-9]"; then
            return $(true)
        fi
    fi
    return $(false)
}


install_python()
{
    # First argument is 3 digit version number, e.g., 3.7.9
    local python_version=$1
    local short_version=$(echo $python_version|sed "s,.[0-9]\\+$,,")

    mkdir -p /opt
    cd /opt
    wget https://www.python.org/ftp/python/$python_version/Python-$python_version.tgz
    tar xzf Python-$python_version.tgz
    cd Python-$python_version
    ./configure --enable-optimizations
    make altinstall
    rm /opt/Python-$python_version.tgz
    ln -s /usr/local/bin/python$short_version /usr/bin/python$short_version
}


# ---------------------------------------------


#
# Check if the user has the privilege to execute this script
if is_root || [[ "$(has_sudo)" == "has_sudo__pass_set" ]] ; then
    echo "Note: Required privileges are ok"
else
    echo "Error: Need root or sudo without password privilege to run this script"
    exit 1
fi


#
# General packages that are needed
DISTRIB_CODENAME=$(grep DISTRIB_CODENAME /etc/lsb-release 2>/dev/null | sed 's,.*=,,')
if [ -n "$DISTRIB_CODENAME" ]; then
    update_test="lsof /var/lib/dpkg/lock-frontend >/dev/null 2>&1"
    if ! upd_ready "$update_test"; then
        printf "\nError: Package manager in use, please try again\n"
        exit 1
    fi
    package_list=($HABANALABS_COMMON habanalabs-dkms)
    if driver_install_check; then
        apt-get remove -y ${package_list[@]} | tee $TMPF
        prior_versions=()
        for i in $(seq 1 $(wc -w <<<${package_list[@]})); do prior_versions+=("n/a"); new_versions+=("n/a"); done
        for ((d=0;d<${#package_list[@]};d++)); do
            ver=$(grep "Removing ${package_list[d]} " $TMPF|sed -e 's,.*(,,' -e 's,).*,,')
            if [ -n "$ver" ]; then prior_versions[d]="$ver"; fi
        done
        rm -f $TMPF
    fi
    if ! grep -q vault.habana.ai /etc/apt/sources.list.d/artifactory.list 2>/dev/null; then
        echo "deb https://vault.habana.ai/artifactory/debian $DISTRIB_CODENAME main" |\
            tee /etc/apt/sources.list.d/artifactory.list
    fi
    wget -O- https://vault.habana.ai/artifactory/api/gpg/key/public | apt-key add -

    dpkg --configure -a
    apt-get update
    apt-get install -y curl ethtool python3 python3-pip dkms libelf-dev \
         lsof \
         habanalabs-dkms \
         $HABANALABS_COMMON \
         linux-headers-$(uname -r) | tee $TMPF
    for ((d=0;d<${#package_list[@]};d++)); do
        ver=$(grep "Setting up ${package_list[d]} " $TMPF|sed -e 's,.*(,,' -e 's,).*,,')
        if [ -n "$ver" ]; then new_versions[d]="$ver"; fi
    done
    rm -f $TMPF
else
    # Empty (not Ubuntu)
    update_test="test -f /var/run/yum.pid"
    if ! upd_ready "$update_test"; then
        printf "\nError: Package manager in use, please try again\n"
        exit 1
    fi
    package_list=($HABANALABS_COMMON habanalabs)
    prior_versions=()
    rpm_versions=$(rpm -qa | grep "habanalabs")
    for i in $(seq 1 $(wc -w <<<${package_list[@]})); do prior_versions+=("n/a"); new_versions+=("n/a"); done
    for ((d=0;d<${#package_list[@]};d++)); do
        ver=$(egrep "${package_list[d]}-[0-9]" <<<$rpm_versions|sed -e "s,.*[a-z]\-,," -e "s,\.el.*,,")
        echo "$d ${package_list[d]} == $ver"
        if [ -n "$ver" ]; then prior_versions[d]="$ver"; fi
    done
    if driver_install_check; then
        rpm -e --nodeps $ABANALABS_COMMON habanalabs
    fi

    DISTRIB_CODENAME=$(grep ^NAME /etc/os-release 2>/dev/null | sed -e 's,.*=,,' -e 's,",,g')
    case "$DISTRIB_CODENAME" in
      "CentOS Linux") os_key="centos7"  ;;
      "CentOS Stream") if (($(grep ^VERSION_ID /etc/os-release 2>/dev/null | sed -e 's,.*=,,' -e 's,",,g') == 8)); then
                           os_key="centos"
                       fi;;
      "Amazon Linux") os_key="AmazonLinux2" ;;
      "Red Hat Enterprise Linux") os_key="rhel/8/8.3";;
      *) unset os_key;;
    esac
    if [ -n "$os_key" ]; then
        {
            echo "[vault]"
            echo "name=Habana Vault"
            echo "baseurl=https://vault.habana.ai/artifactory/$os_key"
            echo "enabled=1"
            echo "gpgcheck=0"
            echo "gpgkey=https://vault.habana.ai/artifactory/$os_key/repodata/repomod.xml.key"
            echo "repo_gpgcheck=0"
        } | tee /etc/yum.repos.d/Habana-Vault.repo
        yum makecache
        if [[ $os_key =~ centos ]]; then
            yum install -y epel-release
        fi
        yum install -y git yum-utils lsof
        yum install -y kernel-devel-$(uname -r)
        yum install -y \
             habanalabs \
             $HABANALABS_COMMON
        rpm_versions=$(rpm -qa | grep "habanalabs")
        for ((d=0;d<${#package_list[@]};d++)); do
            ver=$(egrep "${package_list[d]}-[0-9]" <<<$rpm_versions|sed -e "s,.*[a-z]\-,," -e "s,\.el.*,,")
            #echo "$d ${package_list[d]} == $ver"
            if [ -n "$ver" ]; then new_versions[d]="$ver"; fi
        done
        if [ $os_key = "AmazonLinux2" ]; then
            # Avoid network race condition during driver load
            dracut --omit-drivers habanalabs -f
            echo "blacklist habanalabs" > /etc/modprobe.d/habanalabs.conf
            echo "blacklist habanalabs" > /etc/dracut.conf.d/habanalabs.conf
            tee /lib/systemd/system/habanalabs.service <<EOF
[Unit]
Description=HabanaLabs AWS Helper Service
After=network.target
Before=docker.service

[Service]
Type=oneshot
ExecStart=/sbin/modprobe habanalabs
TimeoutStartSec=600s
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
            {
                echo "systemctl enable habanalabs.service"
                echo "systemctl start habanalabs.service"
            } >> /etc/rc.local
            chmod +x /etc/rc.d/rc.local
        fi
    else
        echo "Error: unsupported OS $DISTRIB_CODENAME"
        exit 2
    fi
fi


#
# Set PYTHON variable to the supported Python version
# Install the right version if needed
if ! grep -q python3 /etc/profile.d/habanalabs.sh 2>/dev/null; then
    case $DISTRIB_CODENAME in
      "bionic") # Ubuntu 18.04
        # U18 has python 3.6 installed by default, but we need 3.8
        if ! python3 --version 2>/dev/null|grep -q " 3.8"; then
            # Install python3.8, add alternatives, and set default
            add-apt-repository -y ppa:deadsnakes/ppa
            apt-get update
            apt-get install -y python3.8 python3-pip
            for py in python python3; do
                update-alternatives --install /usr/bin/$py $py /usr/bin/python3.6 20
                update-alternatives --install /usr/bin/$py $py /usr/bin/python3.8 30
            done
        fi
        apt remove -y python3-apt; apt install -y python3-apt python3.8-dev
        PY=python3.8 ;;
      "focal") PY=python3.8 ;;  # Ubuntu 20.04
      "Amazon Linux") ## Default is 3.7, install 3.8 for v1.3.0 and later
        if [[ ! -d /opt/Python-3.8.12 && -z "$(python3 --version 2>/dev/null|grep 3.8)" ]]; then
            yum install -y libffi-devel
            install_python 3.8.12
        fi
        PY=python3.8
        if ! $PY -m amazon_linux_extras >/dev/null 2>&1; then
            cp -pr /lib/python2.7/site-packages/amazon_linux_extras /usr/local/lib/python3.8/site-packages
        fi ;;
      "CentOS Stream")
        if [[ ! -d /opt/Python-3.8.12 && -z "$(python3 --version 2>/dev/null|grep 3.8)" ]]; then
            yum install -y gcc gcc-c++ zlib zlib-devel
            yum install -y libffi-devel
            install_python 3.8.12
            PY=python3.8
        fi ;;
      *) PY=python3.7 ;;     # All others
    esac
    echo "export PYTHON=/usr/bin/$PY" | tee -a /etc/profile.d/habanalabs.sh
fi
source /etc/profile.d/habanalabs.sh
${PYTHON} -m pip install --upgrade pip


set_huge_pages


if driver_install_check; then
    set +x
    echo "Driver install ok"
    if (($(echo ${prior_versions[@]}|egrep "[0-9]"|wc -w) > 0)); then
        echo "Prior driver versions were present. Upgrade summary:"
        for ((d=0;d<${#package_list[@]};d++)); do
            printf "%26s %10s -> %s\n" ${package_list[d]} ${prior_versions[d]} ${new_versions[d]}
        done
    else
        echo "New install summary:"
        for ((d=0;d<${#package_list[@]};d++)); do
            printf "%26s %s\n" ${package_list[d]} ${new_versions[d]}
        done
    fi
else
    echo "Error: Driver install problem"
    exit 3
fi


echo "Note: Drivers are installed, please reboot the system"
exit 0
