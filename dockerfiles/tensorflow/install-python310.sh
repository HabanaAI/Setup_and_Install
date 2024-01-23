#!/bin/bash
set -e

_BASE_NAME=${1:-"ubuntu22.04"}
_SSL_LIB=""

# preinstall dependencies and define variables
case "${_BASE_NAME}" in
    *ubuntu22.04*)
        echo "Skip install Python3.10 from source on Ubuntu22.04"
        exit 0;
    ;;
    *debian*)
        apt update
        apt install -y libsqlite3-dev libreadline-dev
    ;;
    *rhel*)
        yum install -y sqlite-devel readline-devel
    ;;
    *amzn2*)
        yum install -y sqlite-devel readline-devel
        wget -nv -O /opt/openssl-1.1.1w.tar.gz https://github.com/openssl/openssl/releases/download/OpenSSL_1_1_1w/openssl-1.1.1w.tar.gz && \
            cd /opt/ && \
            tar xzf openssl-1.1.1w.tar.gz && \
            rm -rf openssl-1.1.1w.tar.gz && \
            cd openssl-1.1.1w && \
            ./config --prefix=/usr/local/openssl-1.1.1w shared zlib && \
            make && make install
        ln -s /etc/pki/tls/cert.pem /usr/local/openssl-1.1.1w/ssl/cert.pem

        PATH=$PATH:/usr/local/protoc/bin:/usr/local/openssl-1.1.1w/bin
        LD_LIBRARY_PATH=/usr/local/openssl-1.1.1w/lib:$LD_LIBRARY_PATH
        _SSL_LIB="--with-openssl=/usr/local/openssl-1.1.1w"
    ;;
esac

# install Python
wget -nv -O /opt/Python-3.10.9.tgz https://www.python.org/ftp/python/3.10.9/Python-3.10.9.tgz
cd /opt/
tar xzf Python-3.10.9.tgz
rm -f Python-3.10.9.tgz
cd Python-3.10.9
./configure --enable-optimizations --enable-loadable-sqlite-extensions --enable-shared $_SSL_LIB
make -j && make altinstall

# post install
case "${_BASE_NAME}" in
    *rhel8*)
        alternatives --install /usr/bin/python3 python3 /usr/local/bin/python3.10 3 && \
        alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 2 && \
        alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1 && \
        alternatives --set python3 /usr/local/bin/python3.10
    ;;
    *amzn2*)
        update-alternatives --install /usr/bin/python3 python3 /usr/local/bin/python3.10 3 && \
        update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 2 && \
        update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 1
    ;;
    *debian*)
        update-alternatives --install /usr/bin/python3 python3 /usr/local/bin/python3.10 3
        update-alternatives --install /usr/bin/python3 python3 /usr/local/bin/python3.8 2
        update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 1
    ;;
esac

python3 -m pip install --upgrade pip setuptools

