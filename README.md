# Gaudi Setup and Installation

## Table Of Contents
* [Setting Up and Installing Using Docker Images](#Setting-Up-and-Installing-Using-Docker-Images)
* [How to Build Docker Images from Habana Dockerfiles](#How-to-Build-Docker-Images-from-Habana-Dockerfiles)
* [Ubuntu Bare Metal Installation](#Ubuntu-Bare-Metal-Installation)

## Setting Up and Installing Using Docker Images
### Setup base drivers
If the driver needs to be upadated or installed on a fresh system, please use the following directions (Ubuntu 20.04):

1. Remove old packages habanalabs-dkms
```
sudo dpkg -P habanalabs-dkms
```
2. Download and install habanalabs-dkms --  **TODO: This is an internal link, does not work, would need external Artifacotry**
```
sudo wget https://vault.habana.ai/artifactory/debian/focal/pool/main/h/habanalabs/habanalabs-dkms_0.12.0-353_all.deb
sudo dpkg -i habanalabs-dkms_0.12.0-353_all.deb
```
3. Unload the driver if loaded
```
sudo rmmod habanalabs
```
4. Update firmware. Be careful when updating firmware - it cannot be interrupted. Otherwise, the system may become non-functional.
```
sudo hl-fw-loader --yes
```
5. Load the driver
```
sudo modprobe habanalabs
```
Once the above steps are completed, driver and firmware has been updated.
Please refer to the following instructions on how to ensure setup has completed properly:
[Package setup checks](#Package-setup-checks)

### Install the Docker image
1. Stop running dockers
```
docker stop $(docker ps -a -q)
```

2. Download docker ---   **Note THIS IS an INTERNAL repo, this will be converted to Docker Hub for final usage**
```
docker pull vault.habana.ai/gaudi-docker/0.12.0/ubuntu20.04/habanalabs/tensorflow-installer:0.12.0-353
```

### Launch the image
1. Run docker ---  Note: this will Need the external Artifacotry for this to work.
**NOTE:** This assumes Imagenet dataset is under /opt/datasets/imagenet on the host. Modify accordingly.
```
docker run -td --device=/dev/hl_controlD0:/dev/hl_controlD0 --device=/dev/hl_controlD1:/dev/hl_controlD1 --device=/dev/hl_controlD2:/dev/hl_controlD2 --device=/dev/hl_controlD3:/dev/hl_controlD3 --device=/dev/hl_controlD4:/dev/hl_controlD4 --device=/dev/hl_controlD5:/dev/hl_controlD5 --device=/dev/hl_controlD6:/dev/hl_controlD6 --device=/dev/hl_controlD7:/dev/hl_controlD7 --device=/dev/hl0:/dev/hl0 --device=/dev/hl1:/dev/hl1 --device=/dev/hl2:/dev/hl2 --device=/dev/hl3:/dev/hl3 --device=/dev/hl4:/dev/hl4 --device=/dev/hl5:/dev/hl5 --device=/dev/hl6:/dev/hl6 --device=/dev/hl7:/dev/hl7 -e DISPLAY=$DISPLAY -e LOG_LEVEL_ALL=6 -v /sys/kernel/debug:/sys/kernel/debug -v /tmp/.X11-unix:/tmp/.X11-unix:ro -v /tmp:/tmp -v /opt/datasets/imagenet:/root/tensorflow_datasets/imagenet --net=host --ulimit memlock=-1:-1 vault.habana.ai/gaudi-docker/0.12.0/ubuntu20.04/habanalabs/tensorflow-installer:0.12.0-353
```
OPTIONAL with mounted shared folder to transfer files out of docker:
```
docker run -td --device=/dev/hl_controlD0:/dev/hl_controlD0 --device=/dev/hl_controlD1:/dev/hl_controlD1 --device=/dev/hl_controlD2:/dev/hl_controlD2 --device=/dev/hl_controlD3:/dev/hl_controlD3 --device=/dev/hl_controlD4:/dev/hl_controlD4 --device=/dev/hl_controlD5:/dev/hl_controlD5 --device=/dev/hl_controlD6:/dev/hl_controlD6 --device=/dev/hl_controlD7:/dev/hl_controlD7 --device=/dev/hl0:/dev/hl0 --device=/dev/hl1:/dev/hl1 --device=/dev/hl2:/dev/hl2 --device=/dev/hl3:/dev/hl3 --device=/dev/hl4:/dev/hl4 --device=/dev/hl5:/dev/hl5 --device=/dev/hl6:/dev/hl6 --device=/dev/hl7:/dev/hl7 -e DISPLAY=$DISPLAY -e LOG_LEVEL_ALL=6 -v /sys/kernel/debug:/sys/kernel/debug -v /tmp/.X11-unix:/tmp/.X11-unix:ro -v /tmp:/tmp -v ~/shared:/root/shared -v /opt/dataset/imagenet:/root/tensorflow_datasets/imagenet --net=host --ulimit memlock=-1:-1 vault.habana.ai/gaudi-docker/0.12.0/ubuntu20.04/habanalabs/tensorflow-installer:0.12.0-353
```

2. Check name of your docker
```
docker ps
```

3. Run bash in your docker
```
docker exec -ti <NAME> bash
```
Once you have launched the image, you can refer to the following for how to start running with Tensorflow:
[Model Examples Tensorflow](https://github.com/habana-labs-demo/ResnetModelExample/blob/master/TensorFlow)

## How to Build Docker Images from Habana Dockerfiles
1. Download Docker files and build script from Github to local directory

2. Run build script to generate Docker image
```
./docker_build.sh version revision mode [base,tensorflow,pytorch] os [ubuntu18.04,ubuntu20.04,amzn2]
```
For example:
```
./docker_build.sh 0.12.0 353 tensorflow ubuntu18.04
```

## Ubuntu Bare Metal Installation
The installation for bare metal contains the following Installers:
Mandatory packages: 
* habanalabs-dkms – installs the PCIe driver.
* habanalabs-thunk  – installs the thunk library.
* habanalabs-graph – installs the Graph Compiler and the run-time.

Optional packages:
* habanalabs-fw-tools – installs various fw tools (hlml, hl-smi, etc.)
* habanalabs-qual – installs the qualification application package. See [Gaudi Qualification Library.](https://habana-labs-synapseai-gaudi.readthedocs-hosted.com/en/master/Qualification_Library/GAUDI_Qualification_Library.html#gaudi-qualification-library)

Installing the package with internet connection available allows the network to download and install the required
dependencies for the SynapseAI package (apt get and pip install etc.).
```
sudo dpkg --configure -a
sudo apt-get update
```

The Packages are located in the following locations:
[Amazon Linux 2](https://vault.habana.ai/artifactory/al2/aws/l2)
[Ubuntu 18.04](https://vault.habana.ai/artifactory/debian/bionic/pool/main/h)
[Ubuntu 20.04](https://vault.habana.ai/artifactory/debian/focal/pool/main/h)

### Driver installation
Install the driver using the following command:
```
sudo apt install -y ./habanalabs-dkms_*_all.deb
```

### Update FW
To update the firmware, follow the below steps:
1. Remove the driver:
```
sudo rmmod habanalabs
```
When running on HLS, make sure to remove write protect for burning uboot. For additional details, refer to
Remove write protect for burning uboot.
2. Update the device’s FW:
```
sudo hl-fw-loader
```
3. Start the driver:
```
sudo modprobe habanalabs
```

### Thunk installation
To install the thunk library, use the following command:
```
sudo apt install -y ./habanalabs-thunk-*_all.deb
```

### Graph compiler and run-time installation
To install the graph compiler and run-time, use the following command:
```
sudo apt install -y ./habanalabs-graph-*_all.deb
```

### FW tools installation
To install the firmware tools, use the following command:
```
sudo apt install -y ./habanalabs-fw-tools*.deb
```

### (Optional) qual installation
To install hl_qual, use the following command:
```
sudo apt install -y ./habanalabs-qual*.deb
```

## Package setup checks
This section will provide some commands to help verify the software installation/update has been done properly

### PCI Cards Connected
Check that all the cards show up by running the following command:
```
sudo lspci -tvvv | grep 1da3
```
You should expect to see all Gaudi cards listed.

### PCI Link Status
Check that all the links are trained to Gen3 x16 by running the following command
```
sudo lspci -vvv -s 17:00.0 | grep LnkSta
```
Repeat while modifying the 17:00.0 to walk through all the PCI links from listing of previous command (lspci -tvvv | grep 1da3).
(17.00.0, 18.00.0, 19.00.0, 1a.00.0, 1b.00.0, 1d.00.0, 1e.00.0, ae.00.0, af.00.0 …)

### Firmware Versions Correct
This section requires hl-smi to be used, please refer [this](### FW-tools-installation) section on how to install hl-smi.
Check all of the card's FW versions by running the following commands:
```
sudo hl-smi -q | grep FIT
sudo hl-smi -q | grep SPI
```
You should see the FIT version for each of the cards installed.
Make sure the version matches what is expected (matching the release version you installed)

### Gaudi Clock Freq
This section requires hl-smi to be used, please refer [this](### FW-tools-installation) section on how to install hl-smi.
Check all of the card's frequencies by running the following command:
```
sudo hl-smi -q | grep -A 1 'Clocks$'
```
This will list each card's frequency. Please make sure they are set as expected.

### habanalabs-qual
For some qualification tests, please refer to the following document on how to run and use habanalabs-qual:
[GAUDI_Qualification_Library](https://habana-labs-synapseai-gaudi.readthedocs-hosted.com/en/latest/Qualification_Library/GAUDI_Qualification_Library.html)

### CPU Performance Settings
Check that the CPU setting are set to performance:
```
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```
If not, set CPU setting to Performance:
```
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

## Additional links
For Pytorch:
[Model Examples Pytorch](##TODO##)

For any additional information about installation, please refer to the following link:
[ReadtheDocs Installation Guide](https://habana-labs-synapseai-gaudi.readthedocs-hosted.com/en/latest/Installation_Guide/GAUDI_Installation_Guide.html)

For any additional debugging assistance, please refer to the following link:
[ReadtheDocs Debugging Guide](https://habana-labs-synapseai-gaudi.readthedocs-hosted.com/en/latest/Debugging_Guide/Debugging_Guide.html)

## How to use the Habana Container Runtime

## Managing additional scripts and add-ons
