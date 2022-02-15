#!/bin/bash -e
#
# Copyright 2022 HabanaLabs, Ltd.
#
# SPDX-License-Identifier: Apache-2.0
#
# HabanaLabs script for building docker images

: "${1?"Usage: $0 MODE [tensorflow,pytorch] OS [amzn2,centos8.3,rhel8.3,ubuntu18.04,ubuntu20.04] TF_VERSION(if MODE=tensorflow) [2.7.1, 2.8.0])"}"
: "${2?"Usage: $0 MODE [tensorflow,pytorch] OS [amzn2,centos8.3,rhel8.3,ubuntu18.04,ubuntu20.04] TF_VERSION(if MODE=tensorflow) [2.7.1, 2.8.0])"}"

VERSION="${CUSTOM_VERSION:-1.3.0}"
REVISION="${CUSTOM_REVISION:-499}"
MODE="$1"
OS="$2"
TF_VERSION="$3"
PT_VERSION="1.10.1"
ARTIFACTORY_URL="${CUSTOM_ARTIFACTORY_URL:-vault.habana.ai}"
ARTIFACTORY_REPO="gaudi-docker"

#Arguments validation
case $MODE in
    tensorflow)
        case $TF_VERSION in
            2.7.1|2.8.0);;
            *)
                echo "Provide correct TF_VERSION argument"
                echo "Provided TF_VERSION: $3 - supported TF_VERSION [2.7.1, 2.8.0]"
                exit 1;;
        esac
    ;;
    pytorch)
    ;;
    *)
        echo "Mode not supported!"
        echo "Provided mode: $1 - supported modes: [tensorflow,pytorch]"
        exit 1
    ;;
esac

case $OS in
    amzn2|centos8.3|rhel8.3|ubuntu18.04|ubuntu20.04);;
    *)
        echo "OS not supported!"
        echo "Provided OS: $2 - supported OS'es [amzn2,centos8.3,rhel8.3,ubuntu18.04,ubuntu20.04]"
        exit 1
    ;;
esac


function buildDocker {

    MODE="$1"
    VERSION="$2"
    REVISION="$3"
    OS="$4"
    TF_VERSION="$5"
    PT_VERSION="$6"
    BUILDARGS="--build-arg VERSION="$VERSION"-"$REVISION""

    BASE_NAME="${ARTIFACTORY_URL}/${ARTIFACTORY_REPO}/${VERSION}/${OS}/habanalabs/base-installer"
    DOCKERFILE="Dockerfile_${OS}_base_installer"
    BUILDARGS="--build-arg ARTIFACTORY_URL="$ARTIFACTORY_URL" --build-arg VERSION="$VERSION" --build-arg REVISION="$REVISION""
    IMAGE_NAME="${ARTIFACTORY_URL}/${ARTIFACTORY_REPO}/${VERSION}/${OS}/habanalabs/base-installer:${VERSION}-${REVISION}"

    # check if base image exists locally, if not build base image for requested OS
    if [[ $(docker image inspect $IMAGE_NAME --format="image_exists") != "image_exists" ]]; then
        eval "docker build --network=host --no-cache -t $IMAGE_NAME -f "$DOCKERFILE" "$BUILDARGS" ."
    fi

    case $MODE in
        tensorflow)
            case $OS in
                amzn2|centos8.3|rhel8.3)
                    DOCKERFILE="Dockerfile_${OS}_tensorflow_installer"
                ;;
                ubuntu18.04|ubuntu20.04)
                    DOCKERFILE="Dockerfile_ubuntu_tensorflow_installer"
                ;;
                *)
            esac
                TF_CPU_POSTFIX="-tf-cpu-${TF_VERSION}"
                IMAGE_NAME="${ARTIFACTORY_URL}/${ARTIFACTORY_REPO}/${VERSION}/${OS}/habanalabs/${MODE}-installer${TF_CPU_POSTFIX}:${VERSION}-${REVISION}"
                BUILDARGS+=" --build-arg ARTIFACTORY_URL="$ARTIFACTORY_URL" --build-arg TF_VERSION="$TF_VERSION" --build-arg VERSION="$VERSION" --build-arg REVISION="$REVISION""
        ;;
        pytorch)
            case $OS in
                amzn2|centos8.3|rhel8.3)
                    DOCKERFILE="Dockerfile_${OS}_pytorch_installer"
                ;;
                ubuntu18.04|ubuntu20.04)
                    DOCKERFILE="Dockerfile_ubuntu_pytorch_installer"
                ;;
                *)
            esac
                IMAGE_NAME="${ARTIFACTORY_URL}/${ARTIFACTORY_REPO}/${VERSION}/${OS}/habanalabs/${MODE}-installer-${PT_VERSION}:${VERSION}-${REVISION}"
                BUILDARGS+=" --build-arg ARTIFACTORY_URL="$ARTIFACTORY_URL" --build-arg PT_VERSION="$PT_VERSION" --build-arg VERSION="$VERSION" --build-arg REVISION="$REVISION""
                ;;
        *)
    esac
    BUILDARGS+=" --build-arg BASE_NAME=${BASE_NAME}"
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
echo "PT_VERSION: $PT_VERSION"
echo "ARTIFACTORY_REPO: $ARTIFACTORY_REPO"
echo "---------------------------------------------"

buildDocker "$MODE" "$VERSION" "$REVISION" "$OS" "$TF_VERSION" "$PT_VERSION"