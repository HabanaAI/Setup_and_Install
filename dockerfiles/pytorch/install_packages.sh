#!/bin/bash
set -ex

PT_PACKAGE_NAME="pytorch_modules-v${PT_VERSION}_${VERSION}_${REVISION}.tgz"
OS_STRING="ubuntu${OS_NUMBER}"
case "${BASE_NAME}" in
    *sles15.5* | *suse15.5*)
        OS_STRING="suse155"
    ;;
    *rhel9.2*)
        OS_STRING="rhel92"
    ;;
    *rhel9.4*)
        OS_STRING="rhel94"
    ;;
    *rhel8*)
        OS_STRING="rhel86"
    ;;
    *tencentos*)
        OS_STRING="tencentos31"
    ;;
esac
PT_ARTIFACT_PATH="https://${ARTIFACTORY_URL}/artifactory/gaudi-pt-modules/${VERSION}/${REVISION}/pytorch/${OS_STRING}"

TMP_PATH=$(mktemp --directory)
wget --no-verbose "${PT_ARTIFACT_PATH}/${PT_PACKAGE_NAME}"
tar -zxf "${PT_PACKAGE_NAME}" -C "${TMP_PATH}"/.
pushd "${TMP_PATH}"
./install.sh $VERSION $REVISION
popd

rm -rf "${TMP_PATH}" "${PT_PACKAGE_NAME}"
