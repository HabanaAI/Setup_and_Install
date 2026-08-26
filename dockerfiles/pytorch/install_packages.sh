#!/bin/bash
set -ex
PYTHON_SUFFIX="${PYTHON_SUFFIX:-}"
TORCH_TYPE="${TORCH_TYPE:-fork}"
PYPI_URL="${PYPI_URL:-https://pypi.org/simple/}"
if [ -z "$PYTHON_SUFFIX" ]; then
    PT_PACKAGE_NAME="pytorch_modules-v${PT_VERSION}_${VERSION}_${REVISION}.tgz"
else
    PT_PACKAGE_NAME="pytorch_modules_${PYTHON_SUFFIX}-v${PT_VERSION}_${VERSION}_${REVISION}.tgz"
fi
OS_STRING="ubuntu${OS_NUMBER}"
case "${BASE_NAME}" in
    *rhel9.6*)
        OS_STRING="rhel96"
    ;;
    *rhel9.8*)
        OS_STRING="rhel98"
    ;;
    *tencentos*)
        OS_STRING="tencentos31"
    ;;
    *navix9.4*)
        OS_STRING="navix94"
    ;;
    *navix9.6*)
        OS_STRING="navix96"
    ;;
esac
PT_ARTIFACT_PATH="https://${ARTIFACTORY_URL}/artifactory/gaudi-pt-modules/${VERSION}/${REVISION}/pytorch/${OS_STRING}"

TMP_PATH=$(mktemp --directory)
wget --no-verbose "${PT_ARTIFACT_PATH}/${PT_PACKAGE_NAME}"
tar -zxf "${PT_PACKAGE_NAME}" -C "${TMP_PATH}"/.
pushd "${TMP_PATH}"
PYTHON_INDEX_URL="--extra-index-url ${PYPI_URL}" ./install.sh $VERSION $REVISION $TORCH_TYPE
popd

rm -rf "${TMP_PATH}" "${PT_PACKAGE_NAME}"
