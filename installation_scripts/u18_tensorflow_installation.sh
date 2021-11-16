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

sudo apt update
sudo apt install -y python3.7-dev # mpi4py
sudo apt install -y wget

wget --no-verbose https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-"${OPENMPI_VER}".tar.gz && \
    tar -xvf openmpi-"${OPENMPI_VER}".tar.gz && \
    cd openmpi-"${OPENMPI_VER}" && \
    sudo apt install -y libnuma-dev && \
    ./configure --prefix=$MPI_ROOT && \
    make -j && \
    sudo make install && \
    sudo touch ~root/openmpi-4.0.5_installed && \
    cd - && \
    rm -rf openmpi-"${OPENMPI_VER}"* && \
    sudo /sbin/ldconfig

${PYTHON} -m pip install --user mpi4py==3.0.3

# workaround for broken dependency in TF2.6.0 after release of TF packages for version 2.7.0
${PYTHON} -m pip install --user tensorflow-estimator==2.6.0
${PYTHON} -m pip install --user tensorboard==2.6.0
${PYTHON} -m pip install --user keras==2.6.0
#install base tensorflow package
${PYTHON} -m pip install --user tensorflow-cpu==2.6.0
#install Habana tensorflow bridge & Horovod
${PYTHON} -m pip install --user habana-tensorflow==1.1.0.614 --extra-index-url https://vault.habana.ai/artifactory/api/pypi/gaudi-python/simple
${PYTHON} -m pip install --user habana-horovod==1.1.0.614 --extra-index-url https://vault.habana.ai/artifactory/api/pypi/gaudi-python/simple

source /etc/profile.d/habanalabs.sh
${PYTHON} -c 'import tensorflow as tf;import habana_frameworks.tensorflow as htf;htf.load_habana_module();x = tf.constant(2);y = x + x;assert y.numpy() == 4, "Sanity check failed: Wrong Add output";assert "HPU" in y.device, "Sanity check failed: Operation not executed on Habana";print("Sanity check passed")'
