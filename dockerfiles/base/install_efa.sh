#!/bin/bash -ex

DEFAULT_EFA_INSTALLER_VER=1.34.0
efa_installer_version=${1:-$DEFAULT_EFA_INSTALLER_VER}

tmp_dir=$(mktemp -d)
wget -nv https://efa-installer.amazonaws.com/aws-efa-installer-$efa_installer_version.tar.gz -P $tmp_dir
tar -xf $tmp_dir/aws-efa-installer-$efa_installer_version.tar.gz -C $tmp_dir
RUN_EFA_INSTALLER="./efa_installer.sh -y --skip-kmod --skip-limit-conf --no-verify --minimal"
pushd $tmp_dir/aws-efa-installer
. /etc/os-release
case $ID in
    navix)
        find RPMS/ -name 'dkms*.rpm' -exec rm -f {} \;
        find RPMS/ -name 'efa-*.rpm' -exec rm -f {} \;
        patch -f -p1 -i /tmp/aws_efa_installer.patch --reject-file=aws_efa_installer.patch.rej --no-backup-if-mismatch
    ;;
    rhel)
        # we cannot install dkms packages on RHEL images due to OCP rules
        find RPMS/ -name 'dkms*.rpm' -exec rm -f {} \;
        find RPMS/ -name 'efa-*.rpm' -exec rm -f {} \;
    ;;
    tencentos)
        case $VERSION_ID in
            "3.1")
                find RPMS/ -name 'dkms*.rpm' -exec rm -f {} \;
                find RPMS/ -name 'efa-*.rpm' -exec rm -f {} \;
                rm -rf RPMS/ROCKYLINUX8/x86_64/rdma-core/rdma*
                patch -f -p1 -i /tmp/aws_efa_installer.patch --reject-file=aws_efa_installer.patch.rej --no-backup-if-mismatch
                tmp_dir_ofed=$(mktemp -d)
                wget -O $tmp_dir_ofed/MLNX_OFED.tgz https://artifactory-kfs.habana-labs.com:443/artifactory/devops/tencentos/MLNX_OFED_LINUX-5.8-3.0.7.0-rhel8.4-x86_64.tgz
                pushd $tmp_dir_ofed
                tar -zxf MLNX_OFED.tgz
                ofed_packages_path="mlnx-ofed"
                pushd mlnx-ofed
                yum install pciutils-libs tcsh tk python36 gcc-gfortran kernel-modules fuse-libs numactl-libs -y
                ./mlnxofedinstall --distro RHEL8.4 --skip-distro-check --user-space-only --skip-repo --force
                popd
                popd
                rm -rf $tmp_dir_ofed
                RUN_EFA_INSTALLER="echo 'Skipping EFA installer on TencentOS 3.1'"
            ;;
        esac
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
