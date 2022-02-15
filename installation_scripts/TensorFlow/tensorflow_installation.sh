#!/bin/bash
# *****************************************************************************
# Copyright (c) 2022 Habana Labs, Ltd. an Intel Company
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
REF_PACKAGE="habanalabs-graph" # Synapse GC and Runtime
OPENMPI_VER=4.0.5
HABANA_PIP_VERSION="21.1.1"
SETUPTOOLS_VERSION=41.0.0
MPI_ROOT="/usr/local/openmpi"
PROFILE_FILE="/etc/profile.d/habanalabs.sh"
PATH=$MPI_ROOT/bin:$PATH
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/openmpi/lib/
TF_HABANA_PACKAGES="habana_tensorflow habana_horovod"
KNOWN_TF_PACKAGES="tensorflow tensorflow-cpu tensorflow-gpu intel-tensorflow"
TF_RECOMMENDED_PKG="tensorflow-cpu==2.7.1"

[ -f ${PROFILE_FILE} ] && source ${PROFILE_FILE}
###################################################################################################
#    command line help
###################################################################################################

function help()
{
    echo -e "Help: Setting up execution of TensorFlow for Gaudi"
    echo -e "############################################################"
    echo -e "The script sets up environment for recommended TensorFlow version: ${TF_RECOMMENDED_PKG}."
    echo -e "It auto-detects OS and installed Habana SynapseAI."
    echo -e "List of optional parameters:"
    echo -e "  --tf <tf package>              - full TensorFlow package name and version to install via PIP. (default: '${TF_RECOMMENDED_PKG}')"
    echo -e "                                   I.e. 'tensorflow-cpu==<ver>'. Alternatively, it can be path to remotely located package (as accepted by PIP)."
    echo -e "  --ndeps                        - don't install rpm/deb dependencies"
    echo -e "  --extra_deps                   - install extra model references' rpm/deb dependencies"
    echo -e "  --pip_user <true/false>        - force pip install with or without --user flag. (default: --user is added if USER is not root)"
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
        __is_ubuntu="true"
    elif [[ ($__os == 'ubuntu' && $__os_v == '18.04') ]]; then
        __os_version="ubuntu1804"
        __is_ubuntu="true"
    elif [[ ( $__os == 'rhel' && $__os_v == '8' ) ]]; then
        __os_version="rhel83"
        __is_ubuntu="false"
    elif [[ ( $__os == 'centos' && $__os_v == '8' ) ]]; then
        __os_version="centos83"
        __is_ubuntu="false"
    elif [[ ( $__os == 'amazon' && $__os_v == '2' ) ]]; then
        __os_version="amzn2"
        __is_ubuntu="false"
    else
        echo "Unable to detect Operating system automatically"
        help
        echo "${CMDLINE_USAGE}"
        exit 1
    fi
}

###################################################################################################
#    try to get recommended python version as per selected OS
###################################################################################################
__get_python_ver()
{
    if [[ ($__os_version == "ubuntu1804" ) || \
        ( $__os_version == "amnz2" ) || \
        ( $__os_version == "ubuntu2004" ) || \
        ( $__os_version == "rhel83" ) || \
        ( $__os_version == "centos83" ) \
    ]]; then
        __python_ver="3.8"
    else
        __python_ver="3.8" # the default supported is 3.8 for now, but if/else is left for later extensions
    fi
    if [ "z${PYTHON}" == "z" ]; then
        PYTHON=python${__python_ver}
    fi
    command -v ${PYTHON} 2>&1 > /dev/null
    if [ $? -ne 0 ]; then
        echo "${PYTHON} not found"
        echo "please export PYTHON variable. e.g. "
        echo "export PYTHON=/<path>/python3.8"
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
__install_deps="true"
__install_model_deps="false"

###################################################################################################
#    command line parsing
#    Parse each argument to setup the variables
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
        --os)
            shift
            __os_version=$1
            ;;
        --tf)
            shift
            __tf_pkg=$1
            ;;
        --pip_user)
            shift
            if [ "z${1}" == "ztrue" ]; then
                __python_user_opt="--user"
            else
                __python_user_opt=""
            fi
            ;;
        --ndeps)
            __install_deps="false"
            ;;
        --extra_deps)
            __install_model_deps="true"
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
      amzn2 | rhel83 | centos83)
        pkgname=$(rpm -q ${REF_PACKAGE})
        if [ $? -eq 0 ]; then
            __sw_version="$(echo $pkgname | awk '{ print $3 }' FS='-')"
        fi
        ;;
      *)
        echo "Unknown OS ${__os_version}"
        echo "${CMDLINE_USAGE}"
        exit 1
        ;;
    esac
    if [ "z${__sw_version}" == "z" ]; then
        echo "Unable to detect SynapseAI version. Check if ${REF_PACKAGE} is installed."
        echo "${CMDLINE_USAGE}"
        exit 1
    fi
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
        echo "${CMDLINE_USAGE}"
        exit 1
        ;;
    esac
    if [ "z${__build_no}" == "z" ]; then
        echo "Unable to detect SynapseAI build number. Check if ${REF_PACKAGE} is installed."
        echo "${CMDLINE_USAGE}"
        exit 1
    fi
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

__tf_pkg=${__tf_pkg:-${TF_RECOMMENDED_PKG}}

if [ "z${__sw_version}" == "z" ]; then
    echo "Habana software version is not specified"
    help
    echo "${CMDLINE_USAGE}"
    exit 1
fi
if [ "z${__build_no}" == "z" ]; then
    echo "Habana build number is not specified"
    help
    echo "${CMDLINE_USAGE}"
    exit 1
fi


###################################################################################################
#    uninstall existing python packages if any
#    Args... : list of packages to uninstall
###################################################################################################

uninstall_py_pkgs()
{
    for pkg in $@
    do
        ${PYTHON} -m pip show ${pkg} 2>&1 > /dev/null
        if [ $? -eq 0 ]; then
            ${PYTHON} -m pip uninstall --yes ${pkg}
        fi
    done
}

###################################################################################################
#    install tf python packages
###################################################################################################

install_tf_habana_py_pkgs()
{
    for pkg in ${TF_HABANA_PACKAGES}
    do
        ${PYTHON} -m pip install ${pkg}==${__sw_version}.${__build_no} ${__python_user_opt}
        if [ $? -ne 0 ]; then
            echo "Failed to install ${pkg}."
            echo "${CMDLINE_USAGE}"
            exit 1
        fi
    done
}

###################################################################################################
#    set env required for TensorFlow
###################################################################################################
setup_envs()
{
    ${SUDO} sed -i '/#>>>> TF Habana starts/,/#<<<< TF Habana ends/d' ${PROFILE_FILE}
    echo "#>>>> TF Habana starts" | ${SUDO} tee -a ${PROFILE_FILE}
    echo "export MPI_ROOT=${MPI_ROOT}" | ${SUDO} tee -a ${PROFILE_FILE}
    echo "export OPAL_PREFIX=${MPI_ROOT}" | ${SUDO} tee -a ${PROFILE_FILE}
    echo 'export LD_LIBRARY_PATH=${MPI_ROOT}/lib:${LD_LIBRARY_PATH}' | ${SUDO} tee -a ${PROFILE_FILE}
    echo 'export PATH=${MPI_ROOT}/bin:${PATH}' | ${SUDO} tee -a ${PROFILE_FILE}
    if [ "z$__is_ubuntu" == "zfalse" ]; then
        # For AML/CentOS/RHEL OS'es TFIO_DATAPATH have to be specified to import tensorflow_io lib correctly
        echo "export TFIO_DATAPATH=`${PYTHON} -c 'import tensorflow_io as tfio; import os; print(os.path.dirname(os.path.dirname(tfio.__file__)))'`/" | ${SUDO} tee -a ${PROFILE_FILE}
        # For AML/CentOS/RHEL ca-cert file is expected exactly under /etc/ssl/certs/ca-certificates.crt
        # otherwise curl will fail during access to S3 AWS storage
        if [[ ! -f /etc/ssl/certs/ca-certificates.crt ]]; then
            ${SUDO} ln -s /etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-certificates.crt
        fi
    fi
    echo "#<<<< TF Habana ends" | ${SUDO} tee -a ${PROFILE_FILE}

}

###################################################################################################
#    compile_install_openmpi
###################################################################################################
compile_install_openmpi()
{
    set -e
    if [[ `${MPI_ROOT}/bin/mpirun --version` == *"$OPENMPI_VER"* ]]; then
        echo "OpenMPI found. Skipping installation."
    else
        echo "OpenMPI not found. Installing OpenMPI ${OPENMPI_VER}.."
        wget --no-verbose https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-"${OPENMPI_VER}".tar.gz
        tar -xf openmpi-"${OPENMPI_VER}".tar.gz
        cd openmpi-"${OPENMPI_VER}"
        ./configure --prefix="${MPI_ROOT}"
        make -j
        ${SUDO} make install
        ${SUDO} cp LICENSE ${MPI_ROOT}
        cd -
        ${SUDO} rm -rf openmpi-"${OPENMPI_VER}"*
        ${SUDO} /sbin/ldconfig
    fi
    MPICC=${MPI_ROOT}/bin/mpicc ${PYTHON} -m pip install mpi4py==3.0.3 --no-cache-dir ${__python_user_opt}
    set +e
}

###################################################################################################
#    install_ubuntu_dep_pkgs
###################################################################################################
install_ubuntu_dep_pkgs()
{
    set -e
    HABANA_PIP_VERSION="19.3.1"
    ${SUDO} apt-get update && ${SUDO} apt-get install -y \
    wget \
    python3.8-dev

    ${PYTHON} -m pip install pip=="${HABANA_PIP_VERSION}" ${__python_user_opt}
    ${PYTHON} -m pip install setuptools=="${SETUPTOOLS_VERSION}" ${__python_user_opt}
    set +e
}

install_extra_ubuntu_pkgs()
{
    LIBJEMALLOC="libjemalloc1"
    if [[ ($__os_version == "ubuntu2004" )]]; then
        LIBJEMALLOC="libjemalloc2"
    fi
    set -e
    ${SUDO} apt-get update && ${SUDO} apt-get install -y \
    ${LIBJEMALLOC} \
    protobuf-compiler \
    libgl1
    set +e
}

###################################################################################################
#    install_rhel83_or_centos83_dep_pkgs
###################################################################################################
install_rhel83_or_centos83_dep_pkgs()
{
    set -e
    ${SUDO} dnf install -y \
    redhat-lsb-core \
    cmake \
    wget \
    perl \
    python38-devel
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
    set -e
    ${SUDO} yum install -y \
    redhat-lsb-core \
    cmake \
    wget

    wget https://bootstrap.pypa.io/get-pip.py && \
    ${PYTHON} get-pip.py pip==21.0.1 --no-warn-script-location && \
    rm -rf get-pip.py
    set +e
}

###################################################################################################
#    install_yum_or_dnf_extra_pkgs takes one input arg, "dnf" or "yum"
###################################################################################################
install_yum_or_dnf_extra_pkgs()
{
    set -e

    case ${__os_version} in
    amzn2)
        $1 list installed | grep "epel-release.noarch" || \
        ${SUDO} $1 install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
        ;;
    centos83)
        ${SUDO} $1 install -y epel-release
        ;;
    rhel83)
        ${SUDO} $1 install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
        ;;
    *)
        echo "Unexpected OS ${__os_version} inside install_yum_or_dnf_extra_pkgs() func."
        echo "${CMDLINE_USAGE}"
        exit 1
        ;;
    esac

    ${SUDO} $1 install -y \
    jemalloc \
    mesa-libGL
    ${SUDO} $1 clean all

    if [[ `/usr/local/protoc/bin/protoc --version` == *"3.6.1"* ]]; then
        echo "Protoc 3.6.1 found. Skipping installation."
    else
        wget https://github.com/protocolbuffers/protobuf/releases/download/v3.6.1/protoc-3.6.1-linux-x86_64.zip
        ${SUDO} unzip protoc-3.6.1-linux-x86_64.zip -d /usr/local/protoc
        ${SUDO} rm -rf protoc-3.6.1-linux-x86_64.zip
    fi
    set +e
}

###################################################################################################
#    install_tf_habana_pkgs
###################################################################################################
install_tf_habana_pkgs()
{
    # uninstall Habana TF packages
    uninstall_py_pkgs $TF_HABANA_PACKAGES
    # uninstall any TF in the system
    uninstall_py_pkgs $KNOWN_TF_PACKAGES
    # make sure that no unknow TF package is still installed
    ${PYTHON} -c 'import sys
try:
    import tensorflow;
except ModuleNotFoundError:
    sys.exit(0)
except:
    sys.exit(1)
else:
    sys.exit(1)'
    if [ $? -ne 0 ]; then
        echo "Detected unknown TensorFlow package. Known TF packages: ${KNOWN_TF_PACKAGES}."
        echo "Please uninstall tensorflow from your system and re-run the script."
        echo "${CMDLINE_USAGE}"
        exit 1
    fi

    ${PYTHON} -m pip install ${__tf_pkg} ${__python_user_opt}
    install_tf_habana_py_pkgs

    TF_IO_VER=""
    if [[ ${__tf_pkg} == *"2.7.1"* ]]; then
        TF_IO_VER="0.23.1"
    elif [[ ${__tf_pkg} == *"2.8.0"* ]]; then
        TF_IO_VER="0.24.0"
    else
        echo "Could not determine TensorFlow version from input -tf=${__tf_pkg}. Input string does not match known TF versions."
        echo "${CMDLINE_USAGE}"
        exit 1
    fi
    # install tensorflow-io package with no deps, as it has broken dependency on tensorflow and would try to install non-cpu package
    ${PYTHON} -m pip install --user --no-deps tensorflow-io==${TF_IO_VER} tensorflow-io-gcs-filesystem==${TF_IO_VER}

    setup_envs
    grep -qxF "source ${PROFILE_FILE}" ~/.bashrc || echo "source ${PROFILE_FILE}" >> ~/.bashrc
}

###################################################################################################
#    verify installation
###################################################################################################
verify_installation()
{
    ${PYTHON} -c 'import tensorflow as tf
import habana_frameworks.tensorflow as htf
htf.load_habana_module()
x = tf.constant(2); y = x + x
assert y.numpy() == 4, "Sanity check failed: Wrong Add output"
assert "HPU" in y.device, "Sanity check failed: Operation not executed on Habana Device"
print("Sanity check passed")'

    if [ $? -ne 0 ]; then
        echo "Habana TensorFlow test failed"
        echo "${CMDLINE_USAGE}"
        exit 1
    else
        echo "Habana TensorFlow test completed successfully"
    fi

}

###################################################################################################
#    pkg installation
###################################################################################################
echo "Software Version:  ${__sw_version}"
echo "Software Revision: ${__build_no}"
echo "Operating System:  ${__os_version}"

case ${__os_version} in
  ubuntu1804|ubuntu2004)
    [ "z${__install_deps}" == "ztrue" ] && install_ubuntu_dep_pkgs
    [ "z${__install_model_deps}" == "ztrue" ] && install_extra_ubuntu_pkgs
    ;;
  amzn2)
    [ "z${__install_deps}" == "ztrue" ] && install_amzn2_dep_pkgs
    [ "z${__install_model_deps}" == "ztrue" ] && install_yum_or_dnf_extra_pkgs "yum"
    ;;
  rhel83|centos83)
    [ "z${__install_deps}" == "ztrue" ] && install_rhel83_or_centos83_dep_pkgs
    [ "z${__install_model_deps}" == "ztrue" ] && install_yum_or_dnf_extra_pkgs "dnf"
    ;;
  *)
    echo "Unknown OS ${__os_version}"
    echo "${CMDLINE_USAGE}"
    exit 1
    ;;
esac
compile_install_openmpi
install_tf_habana_pkgs
verify_installation
echo "Setting up execution of TensorFlow for Gaudi is done. Source again ~/.bashrc."
