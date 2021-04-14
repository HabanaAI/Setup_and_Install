#!/bin/bash -e
#
# Copyright 2021 HabanaLabs, Ltd.
#
# SPDX-License-Identifier: Apache-2.0
#
# HabanaLabs script for building docker images

: "${1?"Usage: $0 mode [base,tensorflow,pytorch] os [ubuntu18.04,ubuntu20.04,amzn2] tf_version [2.2.2, 2.4.1]"}"
: "${2?"Usage: $0 mode [base,tensorflow,pytorch] os [ubuntu18.04,ubuntu20.04,amzn2] tf_version [2.2.2, 2.4.1]"}"
: "${2?"Usage: $0 mode [base,tensorflow,pytorch] os [ubuntu18.04,ubuntu20.04,amzn2] tf_version [2.2.2, 2.4.1]"}"

VERSION="0.14.0"
REVISION="420"
MODE="$1"
OS="$2"
TF_VERSION="$3"
ARTIFACTORY_URL="vault.habana.ai/artifactory"
ARTIFACTORY_REPO="docker-local"

function  prepareFiles {

    MODE="$1"
    VERSION="$2"
    REVISION="$3"
    DOCKERFILE=""
    case "$MODE" in
        *base*)
          DOCKERFILE="Dockerfile_"$OS"_"$MODE"_installer"
         ;;
         *tensorflow*)
           DOCKERFILE="Dockerfile_ubuntu_tensorflow_installer"
           if [[ "$OS" == "amzn2" ]]; then
               DOCKERFILE="Dockerfile_amzn2_tensorflow_installer"
           fi
         ;;
         *pytorch*)
           if [[ "$OS" == "amzn2" ]]; then
               DOCKERFILE="Dockerfile_amzn2_pytorch_installer"
           elif [[ "$OS" == *"ubuntu"* ]]; then
               DOCKERFILE="Dockerfile_ubuntu_pytorch_installer"
           else
               echo "OS not supported!"
               exit 1
           fi
         ;;
         *)
           echo "mode not supported!"
           echo "Usage: $0 version revision mode [base,tensorflow,pytorch] os [ubuntu18.04,ubuntu20.04,amzn2]"
           exit 1
         ;;
    esac
}

function buildDocker {

    MODE="$1"
    VERSION="$2"
    REVISION="$3"
    OS="$4"
    TF_VERSION="$5"
    DOCKERFILE=""
    BUILDARGS="--build-arg VERSION="$VERSION"-"$REVISION" --build-arg BASE_NAME="$ARTIFACTORY_URL"/"$ARTIFACTORY_REPO"/"$VERSION"/"$OS"/habanalabs/base-installer"


    case $MODE in
        base)
           DOCKERFILE="Dockerfile_"$OS"_"$MODE"_installer"
           BUILDARGS="--build-arg ARTIFACTORY_URL="$ARTIFACTORY_URL" --build-arg VERSION="$VERSION" --build-arg REVISION="$REVISION""
         ;;
         tensorflow)
           DOCKERFILE="Dockerfile_ubuntu_tensorflow_installer"
           if [[ "$OS" == "amzn2" ]]; then
               DOCKERFILE="Dockerfile_amzn2_tensorflow_installer"
           fi
           TF_CPU_POSTFIX=""
           if [[ "$TF_VERSION" == "2.2."* || "$TF_VERSION" == "2.4."* ]]; then
               TF_CPU_POSTFIX="-tf-cpu-${TF_VERSION}"
           else
               TF_VERSION="2.2.2"  # Set tensorflow-cpu==2.2.2
           fi
           BUILDARGS+=" --build-arg ARTIFACTORY_URL="$ARTIFACTORY_URL" --build-arg TF_VERSION="$TF_VERSION" --build-arg VERSION="$VERSION" --build-arg REVISION="$REVISION""
         ;;
         pytorch)
           if [[ "$OS" == "amzn2" ]]; then
               DOCKERFILE="Dockerfile_amzn2_pytorch_installer"
           elif [[ "$OS" == *"ubuntu"* ]]; then
               DOCKERFILE="Dockerfile_ubuntu_pytorch_installer"
           else
               echo "OS not supported!"
               echo "Usage: $0 version revision mode [base,tensorflow,pytorch] os [ubuntu18.04,ubuntu20.04,amzn2]"
               exit 1
           fi
           BUILDARGS+=" --build-arg ARTIFACTORY_URL="$ARTIFACTORY_URL" --build-arg VERSION="$VERSION" --build-arg REVISION="$REVISION""
         ;;
         *)
           echo "mode not supported!"
              exit 1
         ;;
    esac

    eval "docker build --network=host --no-cache -t "$ARTIFACTORY_URL"/"$ARTIFACTORY_REPO"/"$VERSION"/"$OS"/habanalabs/"$MODE"-installer"${TF_CPU_POSTFIX}":"$VERSION"-"$REVISION" -f "$DOCKERFILE" "$BUILDARGS" ."

}

echo "---------------------------------------------"
echo "Build Arguments:"
echo "$@"
echo "VERSION: $VERSION"
echo "REVISION: $REVISION"
echo "MODE: $MODE"
echo "OS: $OS"
echo "TF_VERSION: $TF_VERSION"
echo "ARTIFACTORY_REPO: $ARTIFACTORY_REPO"
echo "---------------------------------------------"

prepareFiles "$MODE" "$VERSION" "$REVISION"

buildDocker "$MODE" "$VERSION" "$REVISION" "$OS" "$TF_VERSION"