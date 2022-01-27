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
set -x
set -e

sudo yum groupinstall -y "Development Tools"
sudo yum install -y system-lsb-core cmake
sudo yum install -y wget
sudo yum install -y python3-devel

# Install OpenMpi from public sources it maust be installed before requirements,
# That has dependecy with mpi4py package
export OPENMPI_VER=4.0.5
export MPI_ROOT=/usr/local/openmpi
export LD_LIBRARY_PATH=$MPI_ROOT/lib:$LD_LIBRARY_PATH
export OPAL_PREFIX=$MPI_ROOT
export PATH=$MPI_ROOT/bin:$PATH
export PYTHON=/usr/bin/python3.7
echo "export MPI_ROOT=${MPI_ROOT}" | sudo tee -a /etc/profile.d/habanalabs.sh
echo "export OPAL_PREFIX=${MPI_ROOT}" | sudo tee -a /etc/profile.d/habanalabs.sh
echo 'export LD_LIBRARY_PATH=${MPI_ROOT}/lib:${LD_LIBRARY_PATH}' | sudo tee -a /etc/profile.d/habanalabs.sh
echo 'export PATH=${MPI_ROOT}/bin:${PATH}' | sudo tee -a /etc/profile.d/habanalabs.sh

if [[ `${MPI_ROOT}/bin/mpirun --version` == *"$OPENMPI_VER"* ]]; then
    echo "OpenMPI found. Skipping installation."
else
    echo "OpenMPI not found. Installing OpenMPI ${OPENMPI_VER}.."
    wget --no-verbose https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-"${OPENMPI_VER}".tar.gz && \
        tar -xvf openmpi-"${OPENMPI_VER}".tar.gz && \
        cd openmpi-"${OPENMPI_VER}" && \
        ./configure --prefix="${MPI_ROOT}" && \
        make -j && \
        make install && \
        cp LICENSE ${MPI_ROOT} && \
        cd - && \
        rm -rf openmpi-"${OPENMPI_VER}"* && \
        /sbin/ldconfig
fi

# due to changes in Setuptools 60.x, we need to make sure to install older version of package
# (version chosen to be consistent with dockerfiles)
${PYTHON} -m pip install --user setuptools==41.0.0

export MPICC=${MPI_ROOT}/bin/mpicc
${PYTHON} -m pip install --user mpi4py==3.0.3

# uninstall any existing versions of packages
${PYTHON} -m pip uninstall -y habana-horovod habana-tensorflow tensorflow-cpu
# install base tensorflow package
${PYTHON} -m pip install --user tensorflow-cpu==2.7.0
# install tensorflow-io package with no deps, as it has broken dependency on tensorflow and would try to install non-cpu package
${PYTHON} -m pip install --user --no-deps tensorflow-io==0.22.0 tensorflow-io-gcs-filesystem==0.22.0

# For AML/CentOS/RHEL OS'es TFIO_DATAPATH have to be specified to import tensorflow_io lib correctly
export TFIO_DATAPATH=`${PYTHON} -c 'import tensorflow_io as tfio; import os; print(os.path.dirname(os.path.dirname(tfio.__file__)))'`/
# For AML/CentOS/RHEL ca-cert file is expected exactly under /etc/ssl/certs/ca-certificates.crt
# otherwise curl will fail during access to S3 AWS storage
if [[ ! -f /etc/ssl/certs/ca-certificates.crt ]]; then
    sudo ln -s /etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-certificates.crt
fi

# install Habana tensorflow bridge & Horovod
${PYTHON} -m pip install --user habana-tensorflow==1.2.0.585 --extra-index-url https://vault.habana.ai/artifactory/api/pypi/gaudi-python/simple
${PYTHON} -m pip install --user habana-horovod==1.2.0.585 --extra-index-url https://vault.habana.ai/artifactory/api/pypi/gaudi-python/simple

source /etc/profile.d/habanalabs.sh
${PYTHON} -c 'import tensorflow as tf;import habana_frameworks.tensorflow as htf;htf.load_habana_module();x = tf.constant(2);y = x + x;assert y.numpy() == 4, "Sanity check failed: Wrong Add output";assert "HPU" in y.device, "Sanity check failed: Operation not executed on Habana";print("Sanity check passed")'
