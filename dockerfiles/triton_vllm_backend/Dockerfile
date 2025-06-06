# Copyright (c) 2023 HabanaLabs, Ltd.
#
# SPDX-License-Identifier: Apache-2.0
#
# HabanaLabs Dockerfile triton installer layer for Ubuntu 22.04
FROM nvcr.io/nvidia/tritonserver:24.06-py3
ARG ARTIFACTORY_URL
ARG PT_VERSION
ARG VERSION
ARG REVISION
ARG HABANA_PIP_VERSION="22.3"
ARG PT_BUILD_REPO=gaudi-pt-modules
ARG PT_PACKAGE_NAME="pytorch_modules-v"${PT_VERSION}"_"${VERSION}"_"${REVISION}".tgz"
ARG PT_ARTIFACT_PATH="https://"${ARTIFACTORY_URL}"/artifactory/${PT_BUILD_REPO}/"${VERSION}"/"${REVISION}"/pytorch/ubuntu2204"
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
ENV PYTHONPATH=/root:/usr/lib/habanalabs/

ADD model.py .
RUN echo "deb https://${ARTIFACTORY_URL}/artifactory/debian jammy main" | tee -a /etc/apt/sources.list && \
    wget "https://${ARTIFACTORY_URL}/artifactory/api/gpg/key/public" && \
    apt-key add public && rm public && apt-get update && \
    apt-get install -y habanalabs-rdma-core="$VERSION"-"$REVISION" \
        habanalabs-thunk="$VERSION"-"$REVISION" \
        habanalabs-firmware-tools="$VERSION"-"$REVISION" \
        habanalabs-graph="$VERSION"-"$REVISION" && \
    apt-get autoremove --yes && apt-get clean && rm -rf /var/lib/apt/lists/* && \
    sed --in-place "/$ARTIFACTORY_URL/d" /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
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

RUN python3 -m pip install pip==23.3.1 --disable-pip-version-check && \
    python3 -m pip install setuptools==67.3.3 --disable-pip-version-check && \
    python3 -m pip install habana_media_loader=="${VERSION}"."${REVISION}" --disable-pip-version-check

RUN ln -s /usr/bin/python3.10 /usr/bin/python && wget --no-verbose "${PT_ARTIFACT_PATH}/${PT_PACKAGE_NAME}" && \
    mkdir -p /root/habanalabs/pytorch_temp && \
    tar -xf pytorch_modules-v"${PT_VERSION}"_"${VERSION}"_"${REVISION}".tgz -C /root/habanalabs/pytorch_temp/. && \
    python3 -m pip install pip=="${HABANA_PIP_VERSION}" && \
    pip install mpi4py==3.1.4 --disable-pip-version-check && \
    #pip install $(grep -ivE "#|lightning" /root/habanalabs/pytorch_temp/requirements-pytorch.txt | grep .) --no-warn-script-location --disable-pip-version-check && \
    pip install /root/habanalabs/pytorch_temp/*.whl --disable-pip-version-check && \
    pip install $(grep "lightning" /root/habanalabs/pytorch_temp/requirements-pytorch.txt) --disable-pip-version-check && \
    echo "source /etc/profile.d/habanalabs.sh" >> ~/.bashrc && \
    pip uninstall -y pillow && \
    pip uninstall -y pillow-simd && \
    pip install pillow-simd==7.0.0.post3 --disable-pip-version-check && \
    rm -rf /root/habanalabs pytorch_modules-v"${PT_VERSION}"_"${VERSION}"_"${REVISION}".tgz /tmp/*
#RUN python3 -m pip install --no-cache-dir git+https://github.com/HabanaAI/vllm-fork.git@v0.4.2-Gaudi-1.16.0
RUN python3 -m pip install --no-cache-dir git+https://github.com/HabanaAI/vllm-fork.git@275e3250ba6ed8cc13b2d6e4928db73df420e64b

RUN mkdir -p /opt/tritonserver/backends/vllm
COPY model.py /opt/tritonserver/backends/vllm/

ENV LD_PRELOAD=/lib/x86_64-linux-gnu/libtcmalloc.so.4
ENV TCMALLOC_LARGE_ALLOC_REPORT_THRESHOLD=7516192768
