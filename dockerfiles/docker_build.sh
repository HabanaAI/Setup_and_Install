#!/bin/bash -e
#
# Copyright 2023 HabanaLabs, Ltd.
#
# SPDX-License-Identifier: Apache-2.0
#
# HabanaLabs script for building docker images

: "${1?"Usage: $0 MODE [tensorflow,pytorch,triton] OS [amzn2,rhel8.6,ubuntu20.04,ubuntu22.04,debian10.10] [ubuntu20.04] for triton"}"
: "${2?"Usage: $0 MODE [tensorflow,pytorch,triton] OS [amzn2,rhel8.6,ubuntu20.04,ubuntu22.04,debian10.10] [ubuntu20.04] for triton"}"

VERSION="${CUSTOM_VERSION:-1.9.0}"
REVISION="${CUSTOM_REVISION:-580}"
MODE="$1"
OS="$2"
TF_VERSION="2.11.0"
PT_VERSION="1.13.1"
ARTIFACTORY_URL="${CUSTOM_ARTIFACTORY_URL:-vault.habana.ai}"
ARTIFACTORY_REPO="gaudi-docker"

#Arguments validation
case $MODE in
    tensorflow)
        case $OS in
            amzn2|rhel8.6|ubuntu20.04|ubuntu22.04|debian10.10);;
            *)
                echo "Provided OS: $2 not supported for $1 mode - supported OS'es [amzn2,rhel8.6,ubuntu20.04,ubuntu22.04,debian10.10]"
            exit 1
            ;;
        esac
    ;;
    pytorch)
        case $OS in
            amzn2|rhel8.6|ubuntu20.04|ubuntu22.04|debian10.10);;
            *)
                echo "Provided OS: $2 not supported for $1 mode - supported OS'es [amzn2,rhel8.6,ubuntu20.04,ubuntu22.04,debian10.10]"
            exit 1
            ;;
        esac
    ;;
    triton)
        case $OS in
            ubuntu20.04);;
            *)
                echo "Provided OS: $2 not supported for $1 mode - supported OS'es [ubuntu20.04]"
            exit 1
            ;;
        esac
    ;;
    *)
        echo "Mode not supported!"
        echo "Provided mode: $1 - supported modes: [tensorflow,pytorch,triton]"
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

    case $MODE in
        tensorflow|pytorch)
            # check if base image exists locally, if not build base image for requested OS
            if [[ $(docker image inspect $IMAGE_NAME --format="image_exists") != "image_exists" ]]; then
                eval "docker build --network=host --no-cache -t $IMAGE_NAME -f "$DOCKERFILE" "$BUILDARGS" ."
            fi
        ;;
        *)
    esac

    case $MODE in
        tensorflow)
            case $OS in
                amzn2|rhel8.6|debian10.10)
                    DOCKERFILE="Dockerfile_${OS}_tensorflow_installer"
                ;;
                ubuntu20.04|ubuntu22.04)
                    DOCKERFILE="Dockerfile_ubuntu_tensorflow_installer"
                ;;
                *)
            esac
                TF_CPU_POSTFIX="-tf-cpu-${TF_VERSION}"
                IMAGE_NAME="${ARTIFACTORY_URL}/${ARTIFACTORY_REPO}/${VERSION}/${OS}/habanalabs/${MODE}-installer${TF_CPU_POSTFIX}:${VERSION}-${REVISION}"
                BUILDARGS+=" --build-arg TF_VERSION="$TF_VERSION" --build-arg BASE_NAME="$BASE_NAME""
        ;;
        pytorch)
            case $OS in
                amzn2|rhel8.6|debian10.10)
                    DOCKERFILE="Dockerfile_${OS}_pytorch_installer"
                ;;
                ubuntu20.04|ubuntu22.04)
                    DOCKERFILE="Dockerfile_ubuntu_pytorch_installer"
                ;;
                *)
            esac
                IMAGE_NAME="${ARTIFACTORY_URL}/${ARTIFACTORY_REPO}/${VERSION}/${OS}/habanalabs/${MODE}-installer-${PT_VERSION}:${VERSION}-${REVISION}"
                BUILDARGS+=" --build-arg PT_VERSION="$PT_VERSION" --build-arg BASE_NAME="$BASE_NAME""
        ;;
        triton)
            DOCKERFILE="Dockerfile_triton_installer"
            IMAGE_NAME="${ARTIFACTORY_URL}/${ARTIFACTORY_REPO}/${VERSION}/${OS}/habanalabs/${MODE}-installer:${VERSION}-${REVISION}"
            BUILDARGS+=" --build-arg PT_VERSION="$PT_VERSION""
        ;;
        *)
    esac
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