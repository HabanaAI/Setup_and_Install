#!/bin/bash -ex

DEFAULT_EFA_INSTALLER_VER=1.34.0
efa_installer_version=${1:-$DEFAULT_EFA_INSTALLER_VER}

tmp_dir=$(mktemp -d)
wget -nv https://efa-installer.amazonaws.com/aws-efa-installer-$efa_installer_version.tar.gz -P $tmp_dir
tar -xf $tmp_dir/aws-efa-installer-$efa_installer_version.tar.gz -C $tmp_dir
RUN_EFA_INSTALLER="./efa_installer.sh -y --skip-kmod --skip-limit-conf --no-verify"
pushd $tmp_dir/aws-efa-installer
. /etc/os-release
case $ID in
    rhel)
        # we cannot install dkms packages on RHEL images due to OCP rules
        find RPMS/ -name 'dkms*.rpm' -exec rm -f {} \;
        find RPMS/ -name 'efa-*.rpm' -exec rm -f {} \;
        case $VERSION_ID in
            8*)
                dnf install -y RPMS/ROCKYLINUX8/x86_64/rdma-core/*.rpm
            ;;
            9*)
                dnf install -y RPMS/ROCKYLINUX9/x86_64/rdma-core/*.rpm
            ;;
            *)
                echo "Unsupported RHEL version: $VERSION_ID"
                exit 1
            ;;
        esac
        RUN_EFA_INSTALLER="echo 'Skipping EFA installer on RHEL'"
    ;;
    tencentos)
        dnf install -y RPMS/ROCKYLINUX8/x86_64/rdma-core/*.rpm
        patch -f -p1 -i /tmp/tencentos_efa_patch.txt --reject-file=tencentos_efa_patch.rej --no-backup-if-mismatch
    ;;
    ubuntu)
        apt-get update
    ;;
esac

eval $RUN_EFA_INSTALLER

case $ID in
    ubuntu)
        apt-get autoremove && rm -rf /var/lib/apt/lists/*
    ;;
esac

popd
rm -rf $tmp_dir
