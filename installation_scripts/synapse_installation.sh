#!/bin/bash

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
# Usage: sudo -E ./synapse_installation.sh [-s server] [-h]
#   -s server ...... Optional; indicate server for driver package download (default: vault.habana.ai)
#   -h ............. Optional; show help
#   -q ............. Optional; supress output

# OS support (all Python3.8):
# - Ubuntu 18.04
# - Ubuntu 20.04
# - Amazon Linux 2
# - Red Hat Enterprise Linux 8.3

# To preserve existing logs, we generate a new log filename based on
# the script filename
generate_logname()
{
    local cwd=$(dirname $1)
    local fname=$(echo $(basename $1)|sed 's,\.[0-9]*\.log,,')
    lastlogidx=$(ls -1 $fname.*.log 2>/dev/null|awk -F. '{print $2}'|sort -n|tail -1)
    echo $fname.$((lastlogidx+1)).log
}


show_help()
{
    cat <<EOF
Usage: sudo -E ./synapse_installation.sh [-s server] [-h]
   -s server ...... Optional; indicate server for driver package download (default: vault.habana.ai)
   -h ............. Optional; show help
   -q ............. Optional; supress output

This script installs required OS packages and Habanalabs Gaudi drivers
Requirements:
Clean, updated OS installation
User must have sudo access with no password
OS support:
 - Ubuntu 18.04
 - Ubuntu 20.04
 - Amazon Linux 2
 - Red Hat Enterprise Linux 8.3
EOF
}


QUIET=false
LOGFILE="$(basename $0 .sh).log"
if [ -f "$LOGFILE" ]; then
    BASE="$(basename $0 .sh)"
    NEWLOGFILE="$(generate_logname $BASE)"
    mv "$LOGFILE" "$NEWLOGFILE"
fi


#
# Parse options
while getopts hqs: opt; do
    case $opt in
      s) SERVER="$OPTARG" ;;
      q) QUIET=true ;;
      h) show_help >&2; exit 1 ;;
      *) show_help >&2; exit 1 ;;
    esac
done
shift "$((OPTIND-1))" # Shift off the options and optional --.



# == Begin logging ==
{
set -x

#
# Habanalabs packages required
# Note: habanalabs-firmware-tools and habanalabs-qual are optional
HABANALABS_FW_PACKAGES="habanalabs-firmware
                        habanalabs-firmware-tools"
HABANALABS_PACKAGES="habanalabs-thunk
                     habanalabs-graph
                     habanalabs-qual"
SERVER=vault.habana.ai

#
# Temp filename
TMPF=/tmp/$0-$$.log
server_tag=$(sed 's,\..*,,' <<<$SERVER)

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
    if egrep -q "focal|bionic" <<<$VERSION_CODENAME; then
        # Ubuntu 18 or 20
        if dpkg -l | grep -q "habanalabs-firmware" &&
                dpkg -l | grep -q "habanalabs-dkms"; then
            return $(true)
        fi
    else
        # Amazon Linux and rpm based OSs
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

# Use VERSION_CODENAME or NAME to determine the OS type
VERSION_CODENAME=$(cat /etc/os-release|egrep ^VERSION_CODENAME=|awk -F= '{print $2}'|sed 's,",,g')
VERSION_CODENAME=${VERSION_CODENAME:-$(cat /etc/os-release|egrep ^NAME=|awk -F= '{print $2}'|sed 's,",,g')};

if egrep -q "focal|bionic" <<<$VERSION_CODENAME; then
    # Ubuntu 18 or 20
    update_test="lsof /var/lib/dpkg/lock-frontend >/dev/null 2>&1"
    if ! upd_ready "$update_test"; then
        printf "\nError: Package manager in use, please try again\n"
        exit 1
    fi
    package_list=($HABANALABS_FW_PACKAGES habanalabs-dkms $HABANALABS_PACKAGES)
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
    if ! grep -q $SERVER /etc/apt/sources.list.d/artifactory.list 2>/dev/null; then
        echo "deb https://$SERVER/artifactory/debian $VERSION_CODENAME main" |\
            tee /etc/apt/sources.list.d/artifactory.list
    fi
    wget -O- https://$SERVER/artifactory/api/gpg/key/public | apt-key add -

    dpkg --configure -a
    apt-get update
    for p in curl ethtool python3 python3-pip libelf-dev lsof \
             $HABANALABS_FW_PACKAGES \
             dkms habanalabs-dkms \
             $HABANALABS_PACKAGES \
             linux-headers-$(uname -r); do
        echo "== Installing package $p"
        apt-get install -y $p
    done | tee $TMPF
    for ((d=0;d<${#package_list[@]};d++)); do
        ver=$(grep "Setting up ${package_list[d]} " $TMPF|sed -e 's,.*(,,' -e 's,).*,,')
        if [ -n "$ver" ]; then new_versions[d]="$ver"; fi
    done
    rm -f $TMPF
else
    # Not Ubuntu, use yum/rpm as package management
    update_test="test -f /var/run/yum.pid"
    if ! upd_ready "$update_test"; then
        printf "\nError: Package manager in use, please try again\n"
        exit 1
    fi
    package_list=($HABANALABS_FW_PACKAGES habanalabs $HABANALABS_PACKAGES)
    prior_versions=()
    rpm_versions=$(rpm -qa | grep "habanalabs")
    for i in $(seq 1 $(wc -w <<<${package_list[@]})); do prior_versions+=("n/a"); new_versions+=("n/a"); done
    for ((d=0;d<${#package_list[@]};d++)); do
        ver=$(egrep "${package_list[d]}-[0-9]" <<<$rpm_versions|sed -e "s,.*[a-z]\-,," -e "s,\.el.*,,")
        echo "$d ${package_list[d]} == $ver"
        if [ -n "$ver" ]; then prior_versions[d]="$ver"; fi
    done
    if driver_install_check; then
        rpm -e --nodeps $HABANALABS_FW_PACKAGES habanalabs $HABANALABS_PACKAGES
    fi

    case "$VERSION_CODENAME" in
      "Amazon Linux") os_key="AmazonLinux2" ;;
      "Red Hat Enterprise Linux") os_key="rhel/8/8.6";;
      *) unset os_key;;
    esac
    if [ -n "$os_key" ]; then
        {
            echo "[vault]"
            echo "name=Habana $server_tag"
            echo "baseurl=https://$SERVER/artifactory/$os_key"
            echo "enabled=1"
            echo "gpgcheck=0"
            echo "gpgkey=https://$SERVER/artifactory/$os_key/repodata/repomod.xml.key"
            echo "repo_gpgcheck=0"
        } | tee /etc/yum.repos.d/Habana-$server_tag.repo
        yum makecache
        for p in wget git yum-utils lsof kernel-devel-$(uname -r) \
                      $HABANALABS_FW_PACKAGES habanalabs $HABANALABS_PACKAGES; do
            echo "== Installing package $p"
            yum install -y $p
        done
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
        echo "Error: unsupported OS $VERSION_CODENAME"
        exit 2
    fi
fi


#
# Set PYTHON variable to the supported Python version
# Install the right version if needed
if ! grep -q python3 /etc/profile.d/habanalabs.sh 2>/dev/null; then
    case $VERSION_CODENAME in
      "bionic") # Ubuntu 18.04
        # U18 has python 3.6 installed by default, but we need 3.8
        if ! python3 --version 2>/dev/null|grep -q " 3.8"; then
            # Install python3.8, add alternatives, and set default
            add-apt-repository -y ppa:deadsnakes/ppa
            apt-get update
            apt-get install -y python3.8
            for py in python python3; do
                update-alternatives --install /usr/bin/$py $py /usr/bin/python3.6 20
                update-alternatives --install /usr/bin/$py $py /usr/bin/python3.8 30
            done
        fi
        apt remove -y python3-apt; apt install -y python3-apt python3.8-dev python3-pip
        PY=python3.8 ;;
      "focal")  # Ubuntu 20.04
        apt install -y python3-pip
        PY=python3.8 ;;
      "Amazon Linux") ## Default is 3.7, install 3.8 for v1.3.0 and later
        if [[ ! -d /opt/Python-3.8.12 && -z "$(python3 --version 2>/dev/null|grep 3.8)" ]]; then
            yum install -y gcc-c++ libffi-devel openssl
            install_python 3.8.12
        fi
        PY=python3.8
        if ! $PY -m amazon_linux_extras >/dev/null 2>&1; then
            cp -pr /lib/python2.7/site-packages/amazon_linux_extras /usr/local/lib/python3.8/site-packages
        fi ;;
      *) PY=python3.8 ;;     # All others
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

} 2>&1 | if [ $QUIET == true ]; then cat > $LOGFILE; else tee $LOGFILE; fi

exit ${PIPESTATUS[0]}
