#!/bin/bash
set -ex
PYTHON_SUFFIX="${PYTHON_SUFFIX:-}"
TORCH_TYPE="${TORCH_TYPE:-fork}"
if [ -z "$PYTHON_SUFFIX" ]; then
    PT_PACKAGE_NAME="pytorch_modules-v${PT_VERSION}_${VERSION}_${REVISION}.tgz"
else
    PT_PACKAGE_NAME="pytorch_modules_${PYTHON_SUFFIX}-v${PT_VERSION}_${VERSION}_${REVISION}.tgz"
fi
OS_STRING="ubuntu${OS_NUMBER}"
case "${BASE_NAME}" in
    *rhel9.4*)
        OS_STRING="rhel94"
    ;;
    *rhel9.6*)
        OS_STRING="rhel96"
    ;;
    *tencentos*)
        OS_STRING="tencentos31"
    ;;
    *opencloudos9*)
        OS_STRING="opencloudos92"
    ;;
    *navix9*)
        OS_STRING="navix94"
    ;;
esac
PT_ARTIFACT_PATH="https://${ARTIFACTORY_URL}/artifactory/gaudi-pt-modules/${VERSION}/${REVISION}/pytorch/${OS_STRING}"

TMP_PATH=$(mktemp --directory)
wget --no-verbose "${PT_ARTIFACT_PATH}/${PT_PACKAGE_NAME}"
tar -zxf "${PT_PACKAGE_NAME}" -C "${TMP_PATH}"/.
pushd "${TMP_PATH}"
./install.sh $VERSION $REVISION $TORCH_TYPE
popd

rm -rf "${TMP_PATH}" "${PT_PACKAGE_NAME}"
