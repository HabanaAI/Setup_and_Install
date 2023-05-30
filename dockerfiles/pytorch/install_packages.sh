#!/bin/bash
set -ex

pt_package_name="pytorch_modules-v${PT_VERSION}_${VERSION}_${REVISION}.tgz"
os_string="ubuntu${OS_NUMBER}"
habana_version="${VERSION}.${REVISION}"
case "${BASE_NAME}" in
    *rhel8*)
        os_string="rhel86"
    ;;
    *amzn2*)
        os_string="amzn2"
    ;;
    *debian*)
        os_string="debian${OS_NUMBER}"
    ;;
esac
pt_artifact_path="https://${ARTIFACTORY_URL}/artifactory/gaudi-pt-modules/${VERSION}/${REVISION}/pytorch/${os_string}"

mpi_version="3.1.4"
pillow_simd_version="7.0.0.post3"

tmp_path=$(mktemp --directory)
wget --no-verbose "${pt_artifact_path}/${pt_package_name}"
tar -xf "${pt_package_name}" -C "${tmp_path}"/.
pushd "${tmp_path}"
python3 -m pip install mpi4py=="${mpi_version}"
python3 -m pip install $(grep -ivE "#|lightning" requirements-pytorch.txt | grep .) --no-warn-script-location
python3 -m pip install -U habana-pyhlml=="${habana_version}"
python3 -m pip install ./*.whl # install all PT wheel files
python3 -m pip install $(grep "lightning" requirements-pytorch.txt)
python3 -m pip install -U habana-lightning-plugins=="${habana_version}"
python3 -m pip uninstall -y pillow pillow-simd
python3 -m pip install pillow-simd=="${pillow_simd_version}"

popd
# cleanup
rm -rf "${tmp_path}" "${pt_package_name}"
