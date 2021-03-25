# Gaudi Setup and Installation

## Table of Contents
- [Setting Up and Installing Using Docker Images](#setting-up-and-installing-using-docker-images)
- [How to Build Docker Images from Habana Dockerfiles](#how-to-build-docker-images-from-habana-dockerfiles)
- [Ubuntu Bare Metal Installation](#ubuntu-bare-metal-installation)
- [Package setup checks](#package-setup-checks)
- [Additional links](#additional-links)
- [Additional scripts and add-ons](#additional-scripts-and-add-ons)

## Overview
This respository is a "quick start guide" for end users looking to setup their environment.  This will cover the following:  how do download and run Habana specific Docker Images, how to create custom Docker images based on the dockerfiles provided here, and bare metal driver installation.   For more details on the basic driver install, please refer to the [Installation Guide](https://docs.habana.ai/en/latest/Installation_Guide/GAUDI_Installation_Guide.html#gaudi-installation-guide) for more information

## Setting Up and Installing Using Docker Images
### Package Retrieval
1. Download and install the public key:  
```
curl -X GET https://vault.habana.ai/artifactory/api/gpg/key/public | sudo apt-key add -
```
2.  Create an apt source file /etc/apt/sources.list.d/artifactory.list.
3. Add to the file:
```
deb https://vault.habana.ai/artifactory/debian focal main
```
4. Update Debian cache:  
```
sudo dpkg --configure -a
sudo apt-get update
```
### KMD Dependencies
1. Install Deb libraries using the following command:  
```
sudo apt install dkms libelf-dev
```
2. Install headers:  
```
sudo apt install linux-headers-$(uname -r)
```
3. After kernel upgrade, please reboot your machine.

### Setup base drivers
If the driver needs to be upadated or installed on a fresh system, please use the following directions (Ubuntu 20.04):

1. Remove old packages habanalabs-dkms
```
sudo dpkg -P habanalabs-dkms
```
2. Download and install habanalabs-dkms
```
sudo apt install -y habanalabs-dkms=0.13.0-380
```
3. Unload the driver if loaded
```
sudo rmmod habanalabs
```
4. Download and install habanalabs-firmware
```
sudo apt install -y habanalabs-firmware=0.13.0-380
```
5. Update firmware. Be careful when updating firmware - it cannot be interrupted.  
Otherwise, the system may become non-functional.
```
sudo hl-fw-loader --yes
```
6. Load the driver
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

2. Download docker
```
docker pull vault.habana.ai/gaudi-docker/0.13.0/ubuntu20.04/habanalabs/tensorflow-installer:0.13.0-380
```

### Launch the image
1. Run docker ---  Note: this will Need the external Artifacotry for this to work.  
**NOTE:** This assumes Imagenet dataset is under /opt/datasets/imagenet on the host. Modify accordingly.
```
docker run -it -v /dev:/dev --device=/dev:/dev -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice  -v /sys/kernel/debug:/sys/kernel/debug -v /opt/datasets/imagenet:/root/tensorflow_datasets/imagenet --net=host vault.habana.ai/gaudi-docker/0.13.0/ubuntu18.04/habanalabs/tensorflow-installer:0.13.0-380
```
OPTIONAL with mounted shared folder to transfer files out of docker:
```
docker run -it -v /dev:/dev --device=/dev:/dev -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice  -v /sys/kernel/debug:/sys/kernel/debug -v ~/shared:/root/shared -v /opt/datasets/imagenet:/root/tensorflow_datasets/imagenet --net=host vault.habana.ai/gaudi-docker/0.13.0/ubuntu18.04/habanalabs/tensorflow-installer:0.13.0-380
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
[Model References Tensorflow](https://github.com/HabanaAI/Model-References/tree/master/TensorFlow)  
For Pytorch:  
[Model References Pytorch](https://github.com/HabanaAI/Model-References/tree/master/PyTorch)

## How to Build Docker Images from Habana Dockerfiles
1. Download Docker files and build script from Github to local directory

2. Run build script to generate Docker image
```
./docker_build.sh version revision mode [base,tensorflow,pytorch] os [ubuntu18.04,ubuntu20.04,amzn2]
```
For example:
```
./docker_build.sh tensorflow ubuntu20.04
```

## Ubuntu Bare Metal Installation
The installation for bare metal contains the following Installers:  
Mandatory packages:  
* habanalabs-dkms – installs the PCIe driver.
* habanalabs-thunk  – installs the thunk library.
* habanalabs-graph – installs the Graph Compiler and the run-time.

Optional packages:  
* habanalabs-fw-tools – installs various fw tools (hlml, hl-smi, etc.)
* habanalabs-qual – installs the qualification application package. See [Gaudi Qualification Library.](https://docs.habana.ai/en/latest/Qualification_Library/GAUDI_Qualification_Library.html#gaudi-qualification-library)

Installing the package with internet connection available allows the network to download and install the required
dependencies for the SynapseAI package (apt get and pip install etc.).  

The Packages are located in the following locations:  
[Amazon Linux 2](https://vault.habana.ai/ui/repos/tree/General/AmazonLinux2/aws/l2)  
[Ubuntu 18.04](https://vault.habana.ai/ui/repos/tree/General/debian/bionic/pool/main/h/)  
[Ubuntu 20.04](https://vault.habana.ai/ui/repos/tree/General/debian/focal/pool/main/h/)  

### Package Retrieval
1. Download and install the public key:  
```
curl -X GET https://vault.habana.ai/artifactory/api/gpg/key/public | sudo apt-key add -
```
2. Create an apt source file /etc/apt/sources.list.d/artifactory.list.
3. Add to the file:
```
deb https://vault.habana.ai/artifactory/debian focal main
```
4. Update Debian cache:  
```
sudo dpkg --configure -a
sudo apt-get update
```
### KMD Dependencies
1. Install Deb libraries using the following command:  
```
sudo apt install dkms libelf-dev
```
2. Install headers:  
```
sudo apt install linux-headers-$(uname -r)
```
3. After kernel upgrade, please reboot your machine.

### Driver installation
Install the driver using the following command:
```
sudo apt install -y habanalabs-dkms=0.13.0-380
```
### Update FW
To update the firmware, follow the below steps:  
1. Remove the driver:
```
sudo rmmod habanalabs
```
2. Download and install habanalabs-firmware
```
sudo apt install -y habanalabs-firmware=0.13.0-380
```
3. Update the device’s FW:
```
sudo hl-fw-loader --yes
```
4. Start the driver:
```
sudo modprobe habanalabs
```

### Thunk installation
To install the thunk library, use the following command:
```
sudo apt install -y habanalabs-thunk=0.13.0-380
```

### Graph compiler and run-time installation
To install the graph compiler and run-time, use the following command:
```
sudo apt install -y habanalabs-graph=0.13.0-380
```

### FW tools installation
To install the firmware tools, use the following command:
```
sudo apt install -y habanalabs-fw-tools=0.13.0-380
```

### (Optional) qual installation
To install hl_qual, use the following command:
```
sudo apt install -y habanalabs-qual=0.13.0-380
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
This section requires hl-smi to be used, please refer to [this](#FW-tools-installation) section on how to install hl-smi.  
Check all of the card's FW versions by running the following commands:
```
sudo hl-smi -q | grep FIT
sudo hl-smi -q | grep SPI
```
You should see the FIT version for each of the cards installed.  
Make sure the version matches what is expected (matching the release version you installed)

### Gaudi Clock Freq
This section requires hl-smi to be used, please refer to [this](#FW-tools-installation) section on how to install hl-smi.  
Check all of the card's frequencies by running the following command:
```
sudo hl-smi -q | grep -A 1 'Clocks$'
```
This will list each card's frequency. Please make sure they are set as expected.

### habanalabs-qual
For some qualification tests, please refer to the following document on how to run and use habanalabs-qual:  
[GAUDI_Qualification_Library](https://docs.habana.ai/en/latest/Qualification_Library/GAUDI_Qualification_Library.html#gaudi-qualification-library)

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
For any additional information about installation, please refer to the following link:  
[Installation Guide](https://docs.habana.ai/en/latest/Installation_Guide/GAUDI_Installation_Guide.html#gaudi-installation-guide)

For any additional debugging assistance, please refer to the following link:  
[Debugging Guide](https://docs.habana.ai/en/latest/Debugging_Guide/Debugging_Guide.html)

## Additional scripts and add-ons
### manage_network_ifs.sh
This script is used to bring up, take down, set IPs, unset IPs and check for status of the Habana network interfaces.  

The following is the usage of the script:  
```
usage: ./manage_network_ifs.sh [options]  

options:  
       --up         toggle up all Habana network interfaces  
       --down       toggle down all Habana network interfaces  
       --status     print status of all Habana network interfaces  
       --set-ip     set IP for all internal Habana network interfaces  
       --unset-ip   unset IP from all internal Habana network interfaces  
  -v,  --verbose    print more logs  
  -h,  --help       print this help  
```
