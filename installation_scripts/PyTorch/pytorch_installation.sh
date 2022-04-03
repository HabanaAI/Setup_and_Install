#!/bin/bash
# *****************************************************************************
# Copyright (c) 2021 Habana Labs, Ltd. an Intel Company
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
#
# *   Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# *   Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
# OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *****************************************************************************

###################################################################################################
#    set Global variables
#    default settings
###################################################################################################

CMDLINE_USAGE="$0 $*"
REF_PACKAGE="habanalabs-firmware"
ARTIFACTORY_URL=vault.habana.ai
OPENMPI_VER=4.1.2
HABANA_PIP_VERSION="21.1.1"
SETUPTOOLS_VERSION=41.0.0
PROFILE_FILE="/etc/profile.d/habanalabs.sh"
PT_SHARED_LIB_DIR="/usr/lib/habanalabs"
DEFAULT_SW_VERSION="1.4.0"
DEFAULT_BUILD_NO="442"
MPI_ROOT="${MPI_ROOT:-/opt/amazon/openmpi}"

${MPI_ROOT}/bin/mpirun --version 2>/dev/null
if [ $? -eq 0 ]; then
    echo "openmpi is found at ${MPI_ROOT}/bin/mpirun"
else
    MPI_ROOT="/usr/local/openmpi"
fi

PATH=$MPI_ROOT/bin:$PATH
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${MPI_ROOT}/lib/

PT_HABANA_PACKAGES="torch habana_torch habana_torch_dataloader \
                    habana_dataloader transformers fairseq \
                    pytorch_lightning torchvision gather2d_cpp \
                    hmp hb_custom habanaOptimizerSparseAdagrad_cpp \
                    hb_torch habana_torch_hcl habanaOptimizerSparseSgd_cpp \
                    preproc_cpp habana_torch_dataloader habana_torch \
                    HabanaEmbeddingBag_cpp habana_torch_plugin"

PT_HABANA_SHARED_LIBS="libhabana_pytorch_plugin.so libpytorch_synapse_helpers.so \
                _py_pytorch_synapse_logger.so pytorch_synapse_logger.so \
                hb_torch*.so"

[ -f ${PROFILE_FILE} ] && source ${PROFILE_FILE}
###################################################################################################
#    command line help
###################################################################################################

function help()
{
    echo -e "Help: Setting up execution of Pytorch for Gaudi"
    echo -e "############################################################"
    echo -e "  -v <software version>          - Habana software version eg 1.2.0"
    echo -e "  -b <build/revision>             - Habana build number eg: 585 in 1.2.0-585"
    echo -e "  -os <os version>                - OS version <ubuntu2004/ubuntu1804/amzn2/rhel79/rhel83/centos83>"
    echo -e "  -ndep                           - dont install rpm/deb dependecies"
    echo -e "  -sys                            - eg: install python packages without --user"
    echo -e "  -url <link/path to tar file>    - URL/local path of tar file containing Habana PyTorch packages"
    echo -e "  -u                              - eg: install python packages with --user"
}
command -v sudo 2>&1 > /dev/null
if [ $? -ne 0 ] || [ $UID -eq 0 ]; then
    SUDO=""
else
    SUDO=sudo
fi
###################################################################################################
#    try to get automatic OS info
###################################################################################################
__get_os_ver()
{

    __os=$(awk -F= '$1=="NAME" { print tolower($2) ;}' /etc/os-release 2>/dev/null | sed 's/\"//g' | cut -f1 -d" ")
    if [[ $__os == "red" ]]; then
        __os="rhel"
    fi
    if [[ $__os == "debian" ]]; then
        __os_v=$(cat /etc/debian_version)
    elif [[ $__os == "centos" || $__os == "rhel" ]]; then
        __os_v=$(cat /etc/redhat-release | tr -dc '0-9.' | cut -d '.' -f1)
    else
        __os_v=$(source /etc/os-release && echo -n $VERSION_ID)
    fi
    if [[ ($__os == 'ubuntu' && $__os_v == '20.04') ]]; then
        __os_version="ubuntu2004"
    elif [[ ($__os == 'ubuntu' && $__os_v == '18.04') ]]; then
        __os_version="ubuntu1804"
    elif [[ ( $__os == 'rhel' && $__os_v == '8' ) ]]; then
        __os_version="rhel83"
    elif [[ ( $__os == 'rhel' && $__os_v == '7' ) ]]; then
        __os_version="rhel79"
    elif [[ ( $__os == 'centos' && $__os_v == '8' ) ]]; then
        __os_version="centos83"
    elif [[ ( $__os == 'amazon' && $__os_v == '2' ) ]]; then
        __os_version="amzn2"
    else
        echo "Unble to detect Operating system automatically"
        help
        exit 1
    fi
}

###################################################################################################
#    try to get recommended python version as per selected OS
###################################################################################################
__get_python_ver()
{
    if [[ ($__os_version == "ubuntu2004" ) || \
        ( $__os_version == "rhel83" ) || \
        ( $__os_version == "centos83" ) || \
        ( $__os_version == "ubuntu1804" ) || \
        ( $__os_version == "amzn2" ) \
    ]]; then
        __python_ver="3.8"
    else
        __python_ver="3.7"
    fi
    if [ "z${PYTHON}" == "z" ]; then
        PYTHON=python${__python_ver}
    fi
    command -v ${PYTHON} 2>&1 > /dev/null
    if [ $? -ne 0 ]; then
        echo "${PYTHON} not found"
        echo "please export PYTHON variable. e.g. "
        echo "export PYTHON=/<path>/python3.x"
        echo "${CMDLINE_USAGE}"
        exit 1
    fi
}

# Default settings
if [ $UID -ne 0 ]; then
   __python_user_opt="--user"
else
   __python_user_opt=""
fi
__python_user_opt="--user"
__pt_install_deps="true"

###################################################################################################
#    command line parsing
#    Parse each argument to setup the variables
#    Required for versions of openmpi, pip and other pytorch packages
###################################################################################################
while [ -n "$1" ];
do
    case $1 in
        -v)
            shift
            __sw_version=$1
            ;;
        -b)
            shift
            __build_no=$1
            ;;
        -os)
            shift
            __os_version=$1
            ;;
        -pt)
            shift
            __pt_version=$1
            ;;
        -pv)
            shift
            __python_version=$1
            PYTHON=python${__python_ver}
            ;;
        -sys)
            __python_user_opt=""
            ;;
        -u)
            __python_user_opt="--user"
            ;;
        -ndep)
            __pt_install_deps="false"
            ;;
        -url)
            shift
            __pt_pkg_url=$1
            ;;
        -h | --help)
            help
            exit
            ;;
        *)
            echo "$1 unsupported"
            help
            exit
            ;;
    esac
    shift
done

###################################################################################################
#    get version info from installed habana pkg
###################################################################################################
__get_habana_version()
{
    case ${__os_version} in
      ubuntu1804 | ubuntu2004)
        ver=$(dpkg -s ${REF_PACKAGE} 2>/dev/null | grep '^Version:' | awk '{ print $2 }' | awk '{print $1}' FS='-')
        if [ "z${ver}" != "z" ]; then
            __sw_version=${ver}
        fi
        ;;
      amzn2 | rhel79 | rhel83 | centos83)
        pkgname=$(rpm -q ${REF_PACKAGE})
        if [ $? -eq 0 ]; then
            __sw_version="$(echo $pkgname | awk '{ print $3 }' FS='-')"
        fi
        ;;
      *)
        echo "Unknown OS ${__os_version}"
        exit 1
        ;;
    esac
}

###################################################################################################
#    get build info from installed habana pkg
###################################################################################################
__get_habana_build()
{
    case ${__os_version} in
      ubuntu1804 | ubuntu2004)
        build=$(dpkg -s ${REF_PACKAGE} 2>/dev/null | grep '^Version:' | awk '{ print $2 }' | awk '{print $2}' FS='-')
        if [ "z${build}" != "z" ]; then
            __build_no=${build}
        fi
        ;;
      amzn2 | rhel79 | rhel83 | centos83)
        pkgname=$(rpm -q ${REF_PACKAGE})
        if [ $? -eq 0 ]; then
            __build_no="$(echo $pkgname | awk '{ print $4 }' FS='-' | awk '{ print $1 }' FS='.')"
        fi
        ;;
      *)
        echo "Unknown OS ${__os_version}"
        exit 1
        ;;
    esac
}

###################################################################################################
#    trying to set mandatory parameters if not set by user
#    Set sw_version, revision/build_no/ os_version and artifactory link
#    Artifactory link is the base link from where we download the binaries
#    for the python packages
###################################################################################################

if [ "z$__os_version" == "z" ]; then
    __get_os_ver
fi
if [ "z$__python_ver" == "z" ]; then
    __get_python_ver
fi
if [ "z${__sw_version}" == "z" ]; then
    __get_habana_version
fi
if [ "z${__build_no}" == "z" ]; then
    __get_habana_build
fi

__sw_version=${__sw_version:-${DEFAULT_SW_VERSION}}
__build_no=${__build_no:-${DEFAULT_BUILD_NO}}

if [ "z${__sw_version}" == "z" ]; then
    echo "Habana software version is not specified"
    help
    exit 1
fi
if [ "z${__build_no}" == "z" ]; then
    echo "Habana build number is not specified"
    help
    exit 1
fi


###################################################################################################
#    remove pytorch shared libraries
###################################################################################################

rem_pt_shared_libs()
{
    for shfile in ${PT_HABANA_SHARED_LIBS}
    do
        rm -f ${PT_SHARED_LIB_DIR}/${shfile}
    done
}

###################################################################################################
#    uninstall existing python packages if any
###################################################################################################

uninstall_habana_py_pkgs()
{
    for pkg in ${PT_HABANA_PACKAGES}
    do
        ${PYTHON} -m pip show ${pkg} >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            ${PYTHON} -m pip uninstall --yes ${pkg}
        fi
    done
    rem_pt_shared_libs
}

###################################################################################################
#    set env required for pytorch
###################################################################################################
setup_envs()
{
    ${SUDO} sed -i '/#>>>> PT Habana starts/,/#<<<< PT Habana ends/d' ${PROFILE_FILE}
    echo "#>>>> PT Habana starts" | ${SUDO} tee -a ${PROFILE_FILE}
    echo "export MPI_ROOT=${MPI_ROOT}" | ${SUDO} tee -a ${PROFILE_FILE}
    echo "export OPAL_PREFIX=${MPI_ROOT}" | ${SUDO} tee -a ${PROFILE_FILE}
    echo 'export LD_LIBRARY_PATH=${MPI_ROOT}/lib:${LD_LIBRARY_PATH}' | ${SUDO} tee -a ${PROFILE_FILE}
    echo 'export PATH=${MPI_ROOT}/bin:${PATH}' | ${SUDO} tee -a ${PROFILE_FILE}
    echo "#<<<< PT Habana ends" | ${SUDO} tee -a ${PROFILE_FILE}
}

export LANG=en_US.UTF-8

###################################################################################################
#    compile_install_openmpi
###################################################################################################
compile_install_openmpi()
{
    set -e
    ${MPI_ROOT}/bin/mpirun --version 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "OpenMPI found. Skipping installation."
    else
        wget --no-verbose https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-"${OPENMPI_VER}".tar.gz
        tar -xvf openmpi-"${OPENMPI_VER}".tar.gz
        cd openmpi-"${OPENMPI_VER}"
        ./configure --prefix="${MPI_ROOT}"
        make -j
        ${SUDO} make install
        ${SUDO} cp LICENSE ${MPI_ROOT}
        cd -
        ${SUDO} rm -rf openmpi-"${OPENMPI_VER}"*
        ${SUDO} /sbin/ldconfig
        setup_envs
    fi
    MPICC=${MPI_ROOT}/bin/mpicc ${PYTHON} -m pip install mpi4py==3.0.3 --no-cache-dir ${__python_user_opt}
    set +e
}

###################################################################################################
#    install_ubuntu_dep_pkgs
###################################################################################################
install_ubuntu18_dep_pkgs()
{
    __pyver=$(${PYTHON} -c 'import sys; print(".".join(map(str, sys.version_info[:2])))' 2>/dev/null)
    case $__pyver in
      3.8)
        __pydev_pkg="python3.8-dev"
        ;;
      3.7)
        __pydev_pkg="libpython3.7-dev"
        ;;
      *)
        echo "unsupported python verion $__pyver"
        exit 1
        ;;
    esac
    set -e
    HABANA_PIP_VERSION="19.3.1"
    ${SUDO} apt-get update && ${SUDO} apt-get install -y \
    unzip \
    curl \
    libcurl4 \
    moreutils \
    iproute2 \
    libcairo2-dev \
    libglib2.0-dev \
    libselinux1-dev \
    libnuma-dev \
    libpcre2-dev \
    libatlas-base-dev \
    libjpeg-dev \
    liblapack-dev \
    libblas-dev \
    libnuma-dev \
    ${__pydev_pkg} \
    numactl && \
    ${SUDO} apt-get clean
    ${PYTHON} -m pip install pip=="${HABANA_PIP_VERSION}" ${__python_user_opt}
    ${PYTHON} -m pip install setuptools=="${SETUPTOOLS_VERSION}" ${__python_user_opt}
    set +e
}

install_ubuntu20_dep_pkgs()
{
    set -e
    HABANA_PIP_VERSION="19.3.1"
    ${SUDO} apt-get update && ${SUDO} apt-get install -y \
    unzip \
    curl \
    libcurl4 \
    moreutils \
    iproute2 \
    libcairo2-dev \
    libglib2.0-dev \
    libselinux1-dev \
    libnuma-dev \
    libpcre2-dev \
    libatlas-base-dev \
    libjpeg-dev \
    liblapack-dev \
    libblas-dev \
    python3-dev \
    libnuma-dev \
    numactl && \
    ${SUDO} apt-get clean
    ${PYTHON} -m pip install pip=="${HABANA_PIP_VERSION}" ${__python_user_opt}
    ${PYTHON} -m pip install setuptools==45.2.0 ${__python_user_opt}
    set +e
}

###################################################################################################
#    install_rhel83_dep_pkgs
###################################################################################################
install_rhel83_dep_pkgs()
{
    set -e
    ${SUDO} dnf install -y \
    unzip \
    curl \
    redhat-lsb-core \
    openmpi-devel \
    cairo-devel \
    numactl-devel \
    iproute \
    git \
    which \
    libjpeg-devel \
    python38-devel \
    zlib-devel \
    cpupowerutils \
    lapack \
    lapack-devel \
    blas \
    blas-devel \
    numactl && \
    ${SUDO} dnf clean all && ${SUDO} rm -rf /var/cache/yum

    ${PYTHON} -m pip install pip=="${HABANA_PIP_VERSION}" ${__python_user_opt}
    ${PYTHON} -m pip install setuptools=="${SETUPTOOLS_VERSION}" ${__python_user_opt}
    set +e
}


###################################################################################################
#    install_rhel79_dep_pkgs
###################################################################################################
install_rhel79_dep_pkgs()
{
    set -e
    ${SUDO} yum install -y \
    unzip \
    curl \
    redhat-lsb-core \
    openmpi-devel \
    cairo-devel \
    iproute \
    git \
    which \
    libjpeg-devel \
    zlib-devel \
    lapack-devel \
    blas \
    blas-devel \
    numactl && \
    ${SUDO} yum clean all

    ${PYTHON} -m pip install pip=="${HABANA_PIP_VERSION}" ${__python_user_opt}
    ${PYTHON} -m pip install setuptools=="${SETUPTOOLS_VERSION}" ${__python_user_opt}
    set +e
}


###################################################################################################
#    install_centos83_dep_pkgs
###################################################################################################
install_centos83_dep_pkgs()
{
    set -e
    ${SUDO} dnf install -y --enablerepo=powertools \
    libffi-devel \
    unzip \
    curl \
    redhat-lsb-core \
    openmpi-devel \
    numactl-devel \
    cairo-devel \
    iproute \
    git \
    which \
    mesa-libGL \
    libjpeg-devel \
    zlib-devel \
    lapack-devel \
    blas \
    blas-devel \
    numactl && \
    ${SUDO} dnf clean all
    ${PYTHON} -m pip install pip=="${HABANA_PIP_VERSION}" ${__python_user_opt}
    ${PYTHON} -m pip install setuptools=="${SETUPTOOLS_VERSION}" ${__python_user_opt}
    set +e
}

###################################################################################################
#    install_amzn2_dep_pkgs
###################################################################################################
install_amzn2_dep_pkgs()
{
    __pyver=$(${PYTHON} -c 'import sys; print(".".join(map(str, sys.version_info[:2])))' 2>/dev/null)
    case $__pyver in
      3.8)
        __pydev_pkg="python38-devel"
        ;;
      3.7)
        __pydev_pkg="python3-devel"
        ;;
      *)
        echo "unsupported python verion $__pyver"
        exit 1
        ;;
    esac
    set -e
    ${SUDO} yum install -y \
    unzip \
    ${__pydev_pkg} \
    curl \
    redhat-lsb-core \
    openmpi-devel \
    numactl-devel \
    cairo-devel \
    iproute \
    git \
    which \
    libjpeg-devel \
    zlib-devel \
    lapack-devel \
    blas \
    blas-devel \
    sox \
    numactl && \
    ${SUDO} yum clean all

    ${SUDO} amazon-linux-extras install epel -y
    ${SUDO} yum install -y moreutils && ${SUDO} yum clean all

    wget https://bootstrap.pypa.io/get-pip.py && \
    ${PYTHON} get-pip.py pip==21.0.1 --no-warn-script-location && \
    rm -rf get-pip.py
    set +e
}

###################################################################################################
#    install_pt_habana_pkgs
###################################################################################################
install_pt_habana_pkgs()
{
    uninstall_habana_py_pkgs

    PT_PKGS="habanalabs/pytorch_temp"
    mkdir -p ${PT_PKGS}
    if [ -z "${__pt_pkg_url}" ]; then
        DIR_URL="https://${ARTIFACTORY_URL}/artifactory/gaudi-pt-modules/${SW_VERSION}/${REVISION}/${__os_version}/binary"
        PYTORCH_MODULE=$(wget -q ${DIR_URL} -O - | grep -o  "pytorch_modules.*${SW_VERSION}_${REVISION}.tgz" | awk '{print $1}' FS='">')
        if [ -z "$PYTORCH_MODULE" ]; then
            echo "tar file pytorch_modules.*${SW_VERSION}_${REVISION}.tgz not found"
            exit 1
        fi
    else
        PYTORCH_MODULE="$(basename $__pt_pkg_url)"
        DIR_URL="$(dirname $__pt_pkg_url)"
    fi
    if [ -f "$PYTORCH_MODULE" ]; then
        echo "$PYTORCH_MODULE already in place"
    else
        wget ${DIR_URL}/${PYTORCH_MODULE} -O ${PYTORCH_MODULE}
        if [ $? -ne 0 ]; then
            echo "unable to download Habana pytorch whl packages"
            exit 1
        fi
    fi
    tar -xf ${PYTORCH_MODULE} -C ${PT_PKGS}
    ${PYTHON} -m pip install -r ${PT_PKGS}/requirements-pytorch.txt --no-warn-script-location ${__python_user_opt}
    ${PYTHON} -m pip install ${PT_PKGS}/torchvision*.whl ${__python_user_opt}

    ${PYTHON} -m pip uninstall --yes torch
    # Remove the torchvision package after it is installed from
    # the extracted folder. While installing the other .whl
    # files from the extracted folder, there will be one more attempt
    # to install torchvision. Simple reason is avoid the second attempt
    rm -f ${PT_PKGS}/torchvision*.whl
    ${PYTHON} -m pip install ${PT_PKGS}/*.whl ${__python_user_opt}
    ${SUDO} /sbin/ldconfig
    grep -qxF "source ${PROFILE_FILE}" ~/.bashrc || echo "source ${PROFILE_FILE}" >> ~/.bashrc
    ${PYTHON} -m pip uninstall -y pillow
    ${PYTHON} -m pip uninstall -y pillow-simd
    ${PYTHON} -m pip install pillow-simd==7.0.0.post3 ${__python_user_opt}
    rm -rf ${PT_PKGS}
    rm -f ${PYTORCH_MODULE}
}

###################################################################################################
#    verify installation
###################################################################################################
verify_installation()
{
    ${PYTHON} -c "import torch; from habana_frameworks.torch.utils.library_loader import load_habana_module; load_habana_module(); torch.rand(10).to('hpu')"
    if [ $? -ne 0 ]; then
        echo "Habana torch test failed"
        exit 1
    else
        echo "Habana torch test completed successfully"
    fi

}

###################################################################################################
#    pkg installation
###################################################################################################
SW_VERSION=${__sw_version}
REVISION=${__build_no}
PT_VERSION=${__pt_version:-1.10.0}
OS_VERSION=${__os_version:-ubuntu1804}

if [ "z${__pt_pkg_url}" == "z" ]; then
    echo "Software Version:  ${SW_VERSION}"
    echo "Software revision: ${REVISION}"
    echo "Artifactory link:  ${ARTIFACTORY_URL}"
fi
echo "Operating System:  ${OS_VERSION}"

if [ "z${__pt_install_deps}" == "ztrue" ]; then
    case ${__os_version} in
      ubuntu1804)
        install_ubuntu18_dep_pkgs
        ;;
      ubuntu2004)
        install_ubuntu20_dep_pkgs
        ;;
      amzn2)
        install_amzn2_dep_pkgs
        ;;
      rhel79)
        install_rhel79_dep_pkgs
        ;;
      rhel83)
        install_rhel83_dep_pkgs
        ;;
      centos83)
        install_centos83_dep_pkgs
        ;;
      *)
        echo "Unknown OS ${__os_version}"
        exit 1
        ;;
    esac
fi
compile_install_openmpi
install_pt_habana_pkgs
verify_installation
