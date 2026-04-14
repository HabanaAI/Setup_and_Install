# Copyright (c) 2023 HabanaLabs, Ltd.
#
# SPDX-License-Identifier: Apache-2.0
#
# HabanaLabs Dockerfile triton installer layer for Ubuntu 22.04
FROM nvcr.io/nvidia/tritonserver:23.12-py3
ARG ARTIFACTORY_URL
ARG PT_VERSION
ARG VERSION
ARG REVISION
ARG PYPI_URL
ARG HABANA_PIP_VERSION="22.3"
ARG PT_BUILD_REPO=gaudi-pt-modules
ARG PT_PACKAGE_NAME="pytorch_modules-v"${PT_VERSION}"_"${VERSION}"_"${REVISION}".tgz"
ARG PT_ARTIFACT_PATH="https://"${ARTIFACTORY_URL}"/artifactory/${PT_BUILD_REPO}/"${VERSION}"/"${REVISION}"/pytorch/ubuntu2204"
ARG PT_EXTRACT_PATH="/root/habanalabs/pytorch_temp"

ENV DEBIAN_FRONTEND=noninteractive
ENV GC_KERNEL_PATH=/usr/lib/habanalabs/libtpc_kernels.so
ENV HABANA_LOGS=/var/log/habana_logs/
ENV HABANA_SCAL_BIN_PATH=/opt/habanalabs/engines_fw
ENV HABANA_PLUGINS_LIB_PATH=/opt/habanalabs/habana_plugins
ENV PIP_NO_CACHE_DIR=on
ENV PIP_DEFAULT_TIMEOUT=1000
ENV MPI_ROOT=/opt/hpcx/ompi
ENV LD_LIBRARY_PATH=${MPI_ROOT}/lib:/usr/lib/habanalabs:$LD_LIBRARY_PATH
ENV PATH=${MPI_ROOT}/bin:$PATH
ENV OPAL_PREFIX=${MPI_ROOT}
ENV MPICC=${MPI_ROOT}/bin/mpicc
ENV RDMAV_FORK_SAFE=1
ENV PYTHONPATH=/root:/usr/lib/habanalabs
RUN echo "deb https://${ARTIFACTORY_URL}/artifactory/debian jammy main" | tee -a /etc/apt/sources.list && \
    wget "https://${ARTIFACTORY_URL}/artifactory/api/gpg/key/public" && \
    apt-key add public && rm public && apt-get update && \
    apt-get install -y libfdt-dev && \
    apt-get install -y --no-install-recommends \
        habanalabs-rdma-core="$VERSION"-"$REVISION" \
        habanalabs-thunk="$VERSION"-"$REVISION" \
        habanalabs-firmware-tools="$VERSION"-"$REVISION" \
        habanalabs-graph="$VERSION"-"$REVISION" && \
    apt-get autoremove --yes && apt-get clean && rm -rf /var/lib/apt/lists/* && \
    sed --in-place "/$ARTIFACTORY_URL/d" /etc/apt/sources.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    libjemalloc2 \
    libcairo2-dev \
    libglib2.0-dev \
    libhdf5-dev \
    libnuma-dev \
    libpcre2-dev \
    libjpeg-dev \
    liblapack-dev \
    libopenblas-dev \
    numactl \
    libgoogle-perftools-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install pip==24.2 --disable-pip-version-check && \
    python3 -m pip install setuptools==75.1.0 --disable-pip-version-check && \
    python3 -m pip install habana_media_loader=="${VERSION}"."${REVISION}" --extra-index-url ${PYPI_URL} --disable-pip-version-check

RUN ln -s /usr/bin/python3.10 /usr/bin/python && wget --no-verbose "${PT_ARTIFACT_PATH}/${PT_PACKAGE_NAME}" && \
    mkdir -p /root/habanalabs/pytorch_temp && \
    tar -xf pytorch_modules-v"${PT_VERSION}"_"${VERSION}"_"${REVISION}".tgz -C ${PT_EXTRACT_PATH}/. && \
    python3 -m pip install pip=="${HABANA_PIP_VERSION}" && \
    # limiting setuptools version in mpi4py==3.1.6 configuration due to incompatibility with setuptools>=81.0.0 
    wget https://files.pythonhosted.org/packages/b3/17/1d146e0127b66f1945251f130afac430985d2f9d75a3c0330355f21d876a/mpi4py-3.1.6.tar.gz && \
    tar -zxf mpi4py-3.1.6.tar.gz && \
    cd mpi4py-3.1.6 && \
    sed -i 's/setuptools >= 40.9.0/setuptools >= 40.9.0, <= 79.0.1/' pyproject.toml && \
    python3 -m pip install --disable-pip-version-check . && \
    cd - && \
    rm -rf mpi4py-${PYTHON_MPI_VERSION} mpi4py-${PYTHON_MPI_VERSION}.tar.gz && \
    pip install -r ${PT_EXTRACT_PATH}/requirements-pytorch.txt --no-warn-script-location --disable-pip-version-check && \
    pip install ${PT_EXTRACT_PATH}/*.whl --disable-pip-version-check && \
    echo "source /etc/profile.d/habanalabs.sh" >> ~/.bashrc && \
    pip uninstall -y pillow && \
    pip uninstall -y pillow-simd && \
    pip install pillow-simd==7.0.0.post3 --disable-pip-version-check && \
    rm -rf /root/habanalabs pytorch_modules-v"${PT_VERSION}"_"${VERSION}"_"${REVISION}".tgz /tmp/*

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libtcmalloc.so.4
ENV TCMALLOC_LARGE_ALLOC_REPORT_THRESHOLD=7516192768