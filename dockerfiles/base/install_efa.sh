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
    navix)
        find RPMS/ -name 'dkms*.rpm' -exec rm -f {} \;
        find RPMS/ -name 'efa-*.rpm' -exec rm -f {} \;
        dnf install -y RPMS/ROCKYLINUX9/x86_64/rdma-core/*.rpm
        RUN_EFA_INSTALLER="echo 'Skipping EFA installer on RHEL'"
    ;;
    opencloudos)
        find RPMS/ -name 'dkms*.rpm' -exec rm -f {} \;
        find RPMS/ -name 'efa-*.rpm' -exec rm -f {} \;
        rm -rf RPMS/ROCKYLINUX9/x86_64/rdma-core/python3-pyverbs*.rpm
        dnf install -y RPMS/ROCKYLINUX9/x86_64/rdma-core/*.rpm
        RUN_EFA_INSTALLER="echo 'Skipping EFA installer on opencloudos'"
    ;;
    rhel)
        # we cannot install dkms packages on RHEL images due to OCP rules
        find RPMS/ -name 'dkms*.rpm' -exec rm -f {} \;
        find RPMS/ -name 'efa-*.rpm' -exec rm -f {} \;
        case $VERSION_ID in
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
        # dnf install -y RPMS/ROCKYLINUX8/x86_64/rdma-core/*.rpm
        find RPMS/ -name 'dkms*.rpm' -exec rm -f {} \;
        find RPMS/ -name 'efa-*.rpm' -exec rm -f {} \;
        rm -rf RPMS/ROCKYLINUX8/x86_64/rdma-core/rdma*
        patch -f -p1 -i /tmp/tencentos_efa_patch.txt --reject-file=tencentos_efa_patch.rej --no-backup-if-mismatch
        tmp_dir_ofed=$(mktemp -d)
        wget -O $tmp_dir_ofed/MLNX_OFED.tgz https://${ARTIFACTORY_URL}/artifactory/gaudi-installer/deps/MLNX_OFED_LINUX-5.8-3.0.7.0-rhel8.4-x86_64.tgz
        pushd $tmp_dir_ofed
        tar xf MLNX_OFED.tgz
        ofed_packages_path="mlnx-ofed"
        pushd mlnx-ofed
        yum install pciutils-libs tcsh tk python36 gcc-gfortran kernel-modules fuse-libs numactl-libs -y
        ./mlnxofedinstall --distro RHEL8.4 --skip-distro-check --user-space-only --skip-repo --force
        popd
        popd
        rm -rf $tmp_dir_ofed
        RUN_EFA_INSTALLER="echo 'Skipping EFA installer on tencentos'"
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
