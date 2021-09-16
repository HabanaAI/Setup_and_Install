#!/bin/bash -e
#
# Copyright 2021 HabanaLabs, Ltd.
#
# SPDX-License-Identifier: Apache-2.0
#
# HabanaLabs script for building docker images

: "${1?"Usage: $0 mode [tensorflow,pytorch] os [ubuntu18.04,ubuntu20.04,amzn2] tf_version [2.5.1, 2.6.0]"}"
: "${2?"Usage: $0 mode [tensorflow,pytorch] os [ubuntu18.04,ubuntu20.04,amzn2] tf_version [2.5.1, 2.6.0]"}"
: "${2?"Usage: $0 mode [tensorflow,pytorch] os [ubuntu18.04,ubuntu20.04,amzn2] tf_version [2.5.1, 2.6.0]"}"

VERSION="${CUSTOM_VERSION:-1.0.1}"
REVISION="${CUSTOM_REVISION:-81}"
MODE="$1"
OS="$2"
TF_VERSION="$3"
ARTIFACTORY_URL="${CUSTOM_ARTIFACTORY_URL:-vault.habana.ai}"
ARTIFACTORY_REPO="gaudi-docker"

function buildDocker {

    MODE="$1"
    VERSION="$2"
    REVISION="$3"
    OS="$4"
    TF_VERSION="$5"
    BUILDARGS="--build-arg VERSION="$VERSION"-"$REVISION""

    BASE_NAME="${ARTIFACTORY_URL}/${ARTIFACTORY_REPO}/${VERSION}/${OS}/habanalabs/base-installer"
    DOCKERFILE="Dockerfile_${OS}_base_installer"
    BUILDARGS="--build-arg ARTIFACTORY_URL="$ARTIFACTORY_URL" --build-arg VERSION="$VERSION" --build-arg REVISION="$REVISION""
    IMAGE_NAME="${ARTIFACTORY_URL}/${ARTIFACTORY_REPO}/${VERSION}/${OS}/habanalabs/base-installer:${VERSION}-${REVISION}"

    # checki if base image exists locally, if not build base image for requested OS
    if [[ $(docker image inspect $IMAGE_NAME --format="image_exists") != "image_exists" ]]; then
        eval "docker build --network=host --no-cache -t $IMAGE_NAME -f "$DOCKERFILE" "$BUILDARGS" ."
    fi

    case $MODE in
        tensorflow)
        if [ -z "$5" ]; then
            echo "Provide TF_VERSION argument"
            echo "Usage: $0 mode [tensorflow,pytorch] os [ubuntu18.04,ubuntu20.04,amzn2] tf_version [2.5.1, 2.6.0]"
            exit 1
        fi
        DOCKERFILE="Dockerfile_ubuntu_tensorflow_installer"
        if [[ "$OS" == "amzn2" ]]; then
            DOCKERFILE="Dockerfile_amzn2_tensorflow_installer"
        fi
        TF_CPU_POSTFIX="-tf-cpu-${TF_VERSION}"
        BUILDARGS+=" --build-arg ARTIFACTORY_URL="$ARTIFACTORY_URL" --build-arg TF_VERSION="$TF_VERSION" --build-arg VERSION="$VERSION" --build-arg REVISION="$REVISION""
        ;;
        pytorch)
        if [[ "$OS" == "amzn2" ]]; then
            DOCKERFILE="Dockerfile_amzn2_pytorch_installer"
        elif [[ "$OS" == *"ubuntu"* ]]; then
            DOCKERFILE="Dockerfile_ubuntu_pytorch_installer"
        else
            echo "OS not supported!"
            echo "Usage: $0 mode [tensorflow,pytorch] os [ubuntu18.04,ubuntu20.04,amzn2]"
            exit 1
        fi
        BUILDARGS+=" --build-arg ARTIFACTORY_URL="$ARTIFACTORY_URL" --build-arg VERSION="$VERSION" --build-arg REVISION="$REVISION""
        ;;
        *)
        echo "mode not supported!"
        exit 1
        ;;
    esac
        BUILDARGS+=" --build-arg BASE_NAME=${BASE_NAME}"
        IMAGE_NAME="${ARTIFACTORY_URL}/${ARTIFACTORY_REPO}/${VERSION}/${OS}/habanalabs/${MODE}-installer${TF_CPU_POSTFIX}:${VERSION}-${REVISION}"
        echo "DOCKERFILE: ${DOCKERFILE}"
        eval "docker build --network=host --no-cache -t $IMAGE_NAME -f "$DOCKERFILE" "$BUILDARGS" ."
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

buildDocker "$MODE" "$VERSION" "$REVISION" "$OS" "$TF_VERSION"