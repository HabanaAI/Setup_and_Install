# Gaudi Setup and Installation

## Table of Contents
  - [Overview](#overview)
  - [SynapseAi Support Matrix](#synapseai-support-matrix)
  - [Cloud](#cloud)
    - [AWS Deep Learning AMI](#aws-deep-learning-ami)
    - [Habana Deep Learning AMI from AWS Marketplace](#habana-deep-learning-ami-from-aws-marketplace)
    - [Build Your Own AMI](#build-your-own-ami)
  - [On Premises](#on-premises)
    - [Check if Habana Driver/Host Firware are installed](#on-premises)
    - [Install Habana Driver/Host Firmware](#install-habana-driver-and-host-firmware)
    - [Set number of huge pages](#set-number-of-huge-pages)
    - [Bring up network interfaces](#bring-up-network-interfaces)
    - [Will you be using Docker?](#will-you-be-using-docker)
      - No Docker
        - [Check Habana Package Installation for no Docker](#check-habana-package-installation-for-no-docker)
        - [Install SW Stack](#install-sw-stack)
        - [Check TF/Horovod Habana packages](#check-tfhorovod-habana-packages)
        - [Install TF/Horovod Habana packages](#install-tfhorovod-habana-packages)
        - [Check PT Habana packages](#check-pt-habana-packages)
        - [Install PT Habana packages](#install-pt-habana-packages)
      - Docker
        - [Do you want to use prebuilt docker or build docker yourself?](#do-you-want-to-use-prebuilt-docker-or-build-docker-yourself)
        - [How to Build Docker Images from Habana Dockerfiles](#how-to-build-docker-images-from-habana-dockerfiles)
        - [Habana Prebuilt Containers](#habana-prebuilt-containers)
        - [AWS Deep Learning Containers](#aws-deep-learning-containers)
  - [Setup Complete](#setup-complete)
  - [Additional setup checks](#additional-setup-checks)
  - [Additional links](#additional-links)
  - [Additional scripts and add-ons](#additional-scripts-and-add-ons)

<br />

---

<br />

By installing, copying, accessing, or using the software, you agree to be legally bound by the terms and conditions of the Habana software license agreement [defined here](https://habana.ai/habana-outbound-software-license-agreement/).

<br />

---

<br />

## Overview
Welcome to Setup and Installation guide!

This respository is a "quick start guide" for end users looking to setup their environment.

In this Readme you will be directed through the flow of setting up system to run deep learning models on Habana Hardware. Please follow the instructions and answer the questions to be directed through the flow according to your setup/preference.  

A visualization of the flow is provided below to help better understand the available paths:  

![Setup And Install Flow](Setup_and_Install_Flow.png)

At the end of this flow you will be ready to continue to Habana's model references to start running models on your system using Habana Devices.
<br>

## SynapseAi Support Matrix
Please refer to the [Release Notes](https://docs.habana.ai/en/v1.1.1/Release_Notes/GAUDI_Release_Notes.html#support-matrix) for the latest version of the Support Matrix, this support matrix illustrates the OS and Software structure that are used to support the SyanapseAI® Software stack.

## Note on SW versioning
The following documentation and packages correspond to the latest software release version from Habana: 1.1.1-94.  While using with this existing build, it is recommended to use the corresponding 1.1.1 Docker images and Models from the Habana Model-References repository.

<br>

<center>


### Are you using a Cloud computing instance or setting up an system on premises?
[Cloud](#Cloud) • [On Premises](#On-Premises)

</center>

<br />

---

<br />

## Cloud

Please follow the directions from your cloud service provider to setup your instance.  
<br />

<center>

There are currently three paths that can be taken when using cloud service. Please select a path  
[AWS Deep Learning AMI](#AWS-Deep-Learning-AMI) • [Habana Deep Learning AMI from AWS Marketplace](#Habana-Deep-Learning-AMI-from-AWS-Marketplace) • [Build Your Own AMI](#Build-Your-Own-AMI)

</center>

<br />

---

<br />

## AWS Deep Learning AMI

When using the AWS DLAMI everything is pre-setup for execution.
<br />

<center>

You can either run directly on the DLAMI using Habana Model-Refereneces, or launch a container for training  
[Setup python path to run directly on DLAMI using Habana Model-Refereneces](#Setup-Python) • [Run using containers](#Do-you-want-to-use-prebuilt-docker-or-build-docker-yourself)

</center>

<br />

---

<br />

## Setup Python
The packages are installed in the below listed python interpreters.  
Please setup the PYTHON variable if you would like to refer to the model-references:
<details>
<summary>Ubuntu distributions</summary>

  * <details>
    <summary>Ubuntu 18.04</summary>
  
    Please run the following to set python variable
    ```
    export PYTHON=/usr/bin/python3.7
    ```
  
    </details>
  * <details>
    <summary>Ubuntu 20.04</summary>
  
    Please run the following to set python variable
    ```
    export PYTHON=/usr/bin/python3.8
    ```
    
  </details>
</details>
<details>
  <summary>CentOS/Amazon linux 2 distributions</summary>
  
  Please run the following to set python variable
  ```
  export PYTHON=/usr/bin/python3.7
  ```

</details>  
<br>

<table class="tg">
<thead>
  <tr>
    <th class="tg-tlu0"><span>OS</span></th>
    <th class="tg-4i2y" colspan="3">Python Version</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td class="tg-efrg">Ubuntu 18.04</td>
    <td class="tg-7jin" colspan="3">Python 3.7</td>
  </tr>
  <tr>
    <td class="tg-h418">Ubuntu 20.04</td>
    <td class="tg-yjv9" colspan="3">Python 3.8</td>
  </tr>
  <tr>
    <td class="tg-c1uv">Centos</td>
    <td class="tg-4p8a" colspan="3">Python 3.7</td>
  </tr>
  <tr>
    <td class="tg-po5t">Amazon Linux 2</td>
    <td class="tg-jp84" colspan="3">Python 3.7</td>
  </tr>
</tbody>
</table>

<br>
<br>

<center>

Setup complete, please proceed to [Setup Complete](#Setup-Complete)

</center>

<br />

---

<br />

## Habana Deep Learning AMI from AWS Marketplace

When using the Habana Deep Learning AMI from AWS Marketplace, you can either directly use containers or install a framework and proceed from there to run directly on the AMI. 
<br />

<center>

[Run using containers](#Do-you-want-to-use-prebuilt-docker-or-build-docker-yourself) • [Install Tensorflow and run directly on DLAMI](#Check-TFHorovod-Habana-packages) • [Install Pytorch and run directly on DLAMI](#Check-PT-Habana-packages)

</center>

<br />

---

<br />

## Build Your Own AMI

When building your own AMI, please follow the full setup flow to setup AMI.  
In the following, you will be redirected to the On Premises instructions to follow the full setup flow.  
Optionally you can also follow the [aws-habana-baseami-pipeline](https://github.com/aws-samples/aws-habana-baseami-pipeline) repo as a reference to building your own AMI.
<br />

<center>

Please proceed to one of the following  
[On Premises Full Setup](#On-Premises) • [aws-habana-baseami-pipeline](https://github.com/aws-samples/aws-habana-baseami-pipeline)

</center>

<br />

---

<br />

## On Premises

Please ensure the driver and host firmware are installed with version 1.1.1 on your system using the following commands:
<details>
<summary>Ubuntu distributions</summary>

```
dpkg -l | grep habanalabs-firmware
dpkg -l | grep habanalabs-dkms
```

</details>
<details>
<summary>CentOS/Amazon linux 2 distributions</summary>

```
rpm -qa | grep habanalabs-firmware
rpm -qa | grep habanalabs
```

</details>
<br />

<center>

### Does the command above show the package installed?
[Yes (Set number of huge pages)](#Set-number-of-huge-pages) • [No (Install Habana Driver/Host Firmware)](#Install-Habana-Driver-and-Host-Firmware)

</center>

<br />

---

<br />

## Install Habana Driver and Host Firmware
<details>
<summary>Ubuntu distributions</summary>

* <details>
  <summary>Ubuntu 18.04</summary>

  ### Setup package fetching
  1. Download and install the public key:  
  ```
  curl -X GET https://vault.habana.ai/artifactory/api/gpg/key/public | sudo apt-key add -
  ```
  2. Create an apt source file /etc/apt/sources.list.d/artifactory.list
  3. Add the following content to the artifactory.list file:
  ```
  deb https://vault.habana.ai/artifactory/debian bionic main
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
  ### Setup host firmware
  1. Remove old packages habanalabs-firmware
  ```
  sudo dpkg -P habanalabs-firmware
  ```
  2. Download and install habanalabs-firmware
  ```
  sudo apt install -y habanalabs-firmware=1.1.1-94
  ```
  ### Setup base drivers
  The **habanalabs-dkms** package installs both the habanalabs and habanalabs_en (Ethernet) drivers. If automation scripts are used, the scripts must be modified to load/unload both drivers.

  On kernels 5.12 and later, you can load/unload the two drivers in no specific order. On kernels below 5.12, the habanalabs_en driver must be loaded before the habanalabs driver and unloaded after the habanalabs driver.

  The below command installs both the habanalabs and habanalabs_en driver:

  1. Remove old packages habanalabs-dkms
  ```
  sudo dpkg -P habanalabs-dkms
  ```
  2. Download and install habanalabs-dkms
  ```
  sudo apt install -y habanalabs-dkms=1.1.1-94
  ```
  </details>
* <details>
  <summary>Ubuntu 20.04</summary>

  ### Setup package fetching
  1. Download and install the public key:  
  ```
  curl -X GET https://vault.habana.ai/artifactory/api/gpg/key/public | sudo apt-key add -
  ```
  2. Create an apt source file /etc/apt/sources.list.d/artifactory.list
  3. Add the following content to the artifactory.list file:
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
  ### Setup host firmware
  1. Remove old packages habanalabs-firmware
  ```
  sudo dpkg -P habanalabs-firmware
  ```
  2. Download and install habanalabs-firmware
  ```
  sudo apt install -y habanalabs-firmware=1.1.1-94
  ```
  ### Setup base drivers
  The **habanalabs-dkms** package installs both the habanalabs and habanalabs_en (Ethernet) drivers. If automation scripts are used, the scripts must be modified to load/unload both drivers.

  On kernels 5.12 and later, you can load/unload the two drivers in no specific order. On kernels below 5.12, the habanalabs_en driver must be loaded before the habanalabs driver and unloaded after the habanalabs driver.

  The below command installs both the habanalabs and habanalabs_en driver:

  1. Remove old packages habanalabs-dkms
  ```
  sudo dpkg -P habanalabs-dkms
  ```
  2. Download and install habanalabs-dkms
  ```
  sudo apt install -y habanalabs-dkms=1.1.1-94
  ```
  </details>
</details>

<details>
<summary>CentOS distributions</summary>

### Setup package fetching
1. Create this file: /etc/yum.repos.d/Habana-Vault.repo
2. Add the following content to the Habana-Vault.repo file:
```
[vault]

name=Habana Vault

baseurl=https://vault.habana.ai/artifactory/centos7

enabled=1

gpgcheck=0

gpgkey=https://vault.habana.ai/artifactory/centos7/repodata/repomod.xml.key

repo_gpgcheck=0
```
3. Update YUM cache by running the following command:
```
sudo yum makecache
```
4. Verify correct binding by running the following command:
```
yum search habana
```
This will search for and list all packages with the word Habana.

### KMD Dependencies
1. Check your Linux kernel version:
```
uname -r
```
2. Install headers: 
```
sudo yum install -y kernel-devel-$(uname -r)
```
3. After kernel upgrade, please reboot your machine.

### Additional Dependencies
Add yum-utils:
```
sudo yum install -y sudo yum-utils
```  
### Setup host firmware
1. Remove the previous habanalabs-firmware package:
```
sudo yum remove habanalabs-firmware*
```
2. Download and install habanalabs-firmware
```
sudo yum install habanalabs-firmware-1.1.1-94* -y
```
### Setup base drivers
The **habanalabs-dkms** package installs both the habanalabs and habanalabs_en (Ethernet) drivers. If automation scripts are used, the scripts must be modified to load/unload both drivers.

On kernels 5.12 and later, you can load/unload the two drivers in no specific order. On kernels below 5.12, the habanalabs_en driver must be loaded before the habanalabs driver and unloaded after the habanalabs driver.

The below command installs both the habanalabs and habanalabs_en driver:

1. Remove the previous driver package:
```
sudo yum remove habanalabs*
```
2. Download and install new driver:
```
sudo yum install habanalabs-1.1.1-94* -y
```
</details>
<details>
<summary>Amazon linux 2 distributions</summary>

### Setup package fetching
1. Create this file: /etc/yum.repos.d/Habana-Vault.repo
2. Add the following content to the Habana-Vault.repo file:
```
[vault]

name=Habana Vault

baseurl=https://vault.habana.ai/artifactory/AmazonLinux2

enabled=1

gpgcheck=0

gpgkey=https://vault.habana.ai/artifactory/AmazonLinux2/repodata/repomod.xml.key

repo_gpgcheck=0
```
3. Update YUM cache by running the following command:
```
sudo yum makecache
```
4. Verify correct binding by running the following command:
```
yum search habana
```
This will search for and list all packages with the word Habana.

### KMD Dependencies
1. Check your Linux kernel version:
```
uname -r
```
2. Install headers: 
```
sudo yum install -y kernel-devel-$(uname -r)
```
3. After kernel upgrade, please reboot your machine.

### Additional Dependencies
Add yum-utils:
```
sudo yum install -y sudo yum-utils
```  
### Setup host firmware
1. Remove the previous habanalabs-firmware package:
```
sudo yum remove habanalabs-firmware*
```
2. Download and install habanalabs-firmware
```
sudo yum install habanalabs-firmware-1.1.1-94* -y
```
### Setup base drivers
The **habanalabs-dkms** package installs both the habanalabs and habanalabs_en (Ethernet) drivers. If automation scripts are used, the scripts must be modified to load/unload both drivers.

On kernels 5.12 and later, you can load/unload the two drivers in no specific order. On kernels below 5.12, the habanalabs_en driver must be loaded before the habanalabs driver and unloaded after the habanalabs driver.

The below command installs both the habanalabs and habanalabs_en driver:

1. Remove the previous driver package:
```
sudo yum remove habanalabs*
```
2. Download and install new driver:
```
sudo yum install habanalabs-1.1.1-94* -y
```
</details>

<center>

### Please go back and check that driver was installed
[Habana Driver/Host Firmware Check](#On-Premises)

</center>
<br />

---

<br />

## Set number of huge pages
Some training models use huge pages. It is recommended to set the number of huge pages as provided below:
```
#set current hugepages
sudo sysctl -w vm.nr_hugepages=15000
#Remove old entry if exists in sysctl.conf
sudo sed --in-place '/nr_hugepages/d' /etc/sysctl.conf
#Insert huge pages settings to persist
echo "vm.nr_hugepages=15000" | sudo tee -a /etc/sysctl.conf
```

<center>

### Please proceed to
[Bring up network interfaces](#Bring-up-network-interfaces)

</center>

<br />

---

<br />

## Bring up network interfaces
If training using Gaudi network interfaces for multi-node scaleout (external Gaudi network interfaces between servers), please ensure the network interfaces are brought up.  
These interfaces need to be brought up every time the kernel module is loaded or unloaded and reloaded.  

**NOTE:** AWS users no longer need to do this step.
<br>

A reference on how to bring up the interfaces is provided as the manage_network_ifs.sh script in this repo, please use the following commands:
```
# manage_network_ifs.sh requires ethtool
sudo apt-get install ethtool
./manage_network_ifs.sh --up
```
For more information please refer to [this](#manage_network_ifssh) section

<center>

### Please proceed to
[Will you be using docker?](#Will-you-be-using-docker)

</center>

<br />

---

<br />
<center>

### Will you be using Docker?
[Docker](#Do-you-want-to-use-prebuilt-docker-or-build-docker-yourself) • [No Docker](#Check-Habana-Package-Installation-For-No-Docker)

</center>

<br />

---

<br />

## Check Habana Package Installation for no Docker
Please ensure the following software packages are installed on your system with version 1.1.1:
### Required packages:
* habanalabs-dkms – installs the PCIe driver. (Should already be installed in previous steps)
* habanalabs-graph – installs the Graph Compiler and the run-time.
* habanalabs-thunk – installs the thunk library.
* habanalabs-firmware - installs the Gaudi Host Firmware.

### Optional packages:
* habanalabs-firmware-tools – installs various Firmware tools (hlml, hl-smi, etc).
* habanalabs-qual – installs the qualification application package. See [Gaudi Qualification Library.](https://docs.habana.ai/en/v1.1.1/Qualification_Library/GAUDI_Qualification_Library.html)
* habanalabs-container-runtime - installs the container runtime library which eases selection of devices to be mounted in the container.
* habanalabs-aeon – installs demo’s data loader.

Use the following commands to fetch current packages on the system:
<details>
<summary>Ubuntu distributions</summary>

```
dpkg -l | grep habana
```

</details>
<details>
<summary>CentOS/Amazon linux 2 distributions</summary>

```
rpm -qa | grep habana
```

</details>
<br />

<center>

### Are the required packages installed on your system with your expected version?
[Yes (Tensorflow)](#Check-TFHorovod-Habana-packages) • [Yes (Pytorch)](#Check-PT-Habana-packages) • [No](#Install-SW-Stack)

</center>

<br />

---

<br />

## Install SW Stack
<details>
<summary>Ubuntu distributions</summary>

Installing the package with internet connection available allows the network to download and install the required dependencies for the SyanapseAI® package (apt get and pip install etc.).

* <details>
  <summary>Ubuntu 18.04</summary>

  ### Setup package fetching
  1. Download and install the public key:  
  ```
  curl -X GET https://vault.habana.ai/artifactory/api/gpg/key/public | sudo apt-key add -
  ```
  2. Create an apt source file /etc/apt/sources.list.d/artifactory.list
  3. Add the following content to the artifactory.list file:
  ```
  deb https://vault.habana.ai/artifactory/debian bionic main
  ```
  4. Update Debian cache:  
  ```
  sudo dpkg --configure -a
  sudo apt-get update
  ```  
  ### Graph compiler and run-time installation
  To install the graph compiler and run-time, use the following command:
  ```
  sudo apt install -y habanalabs-graph=1.1.1-94
  ```
  ### Thunk installation
  To install the thunk library, use the following command:
  ```
  sudo apt install -y habanalabs-thunk=1.1.1-94
  ```
  ### Host firmware installation
  Install the Firmware package:
  ```
  sudo apt install -y habanalabs-firmware=1.1.1-94
  ```
  ### (Optional) FW tools installation
  To install the firmware tools, use the following command:
  ```
  # lsof required
  sudo apt install -y lsof
  sudo apt install -y habanalabs-firmware-tools=1.1.1-94
  ```

  ### (Optional) qual installation
  To install hl_qual, use the following command:
  ```
  sudo apt install -y habanalabs-qual=1.1.1-94
  ```

  ### (Optional) aeon installation
  To install aeon, use the following command:
  ```
  sudo apt install -y habanalabs-aeon=1.1.1-94
  ```
  </details>
* <details>
  <summary>Ubuntu 20.04</summary>

  ### Setup package fetching
  1. Download and install the public key:  
  ```
  curl -X GET https://vault.habana.ai/artifactory/api/gpg/key/public | sudo apt-key add -
  ```
  2. Create an apt source file /etc/apt/sources.list.d/artifactory.list
  3. Add the following content to the artifactory.list file:
  ```
  deb https://vault.habana.ai/artifactory/debian focal main
  ```
  4. Update Debian cache:  
  ```
  sudo dpkg --configure -a
  sudo apt-get update
  ```  
  ### Graph compiler and run-time installation
  To install the graph compiler and run-time, use the following command:
  ```
  sudo apt install -y habanalabs-graph=1.1.1-94
  ```
  ### Thunk installation
  To install the thunk library, use the following command:
  ```
  sudo apt install -y habanalabs-thunk=1.1.1-94
  ```
  ### Host firmware installation 
  Install the Firmware package:
  ```
  sudo apt install -y habanalabs-firmware=1.1.1-94
  ```
  ### (Optional) FW tools installation
  To install the firmware tools, use the following command:
  ```
  # lsof required
  sudo apt install -y lsof
  sudo apt install -y habanalabs-firmware-tools=1.1.1-94
  ```

  ### (Optional) qual installation
  To install hl_qual, use the following command:
  ```
  sudo apt install -y habanalabs-qual=1.1.1-94
  ```

  ### (Optional) aeon installation
  To install aeon, use the following command:
  ```
  sudo apt install -y habanalabs-aeon=1.1.1-94
  ```
  </details>
</details>

<details>
<summary>CentOS distributions</summary>

Installing the package with internet connection available allows the network to download and install the required dependencies for the SyanapseAI® package (yum install and pip install etc.).

### Setup package fetching
1. Create this file: /etc/yum.repos.d/Habana-Vault.repo
2. Add the following content to the Habana-Vault.repo file:
```
[vault]

name=Habana Vault

baseurl=https://vault.habana.ai/artifactory/centos7

enabled=1

gpgcheck=0

gpgkey=https://vault.habana.ai/artifactory/centos7/repodata/repomod.xml.key

repo_gpgcheck=0
```
3. Update YUM cache by running the following command:
```
sudo yum makecache
```
4. Verify correct binding by running the following command:
```
yum search habana
```
This will search for and list all packages with the word Habana.

### Graph compiler and run-time installation
To install the graph compiler and run-time, use the following command:
```
sudo yum install habanalabs-graph-1.1.1-94* -y
```
### Thunk installation
To install the thunk library, use the following command:
```
sudo yum install habanalabs-thunk-1.1.1-94* -y
```
### Host firmware installation
Install the Firmware package:
```
sudo yum install habanalabs-firmware-1.1.1-94* -y
```
### (Optional) FW tools installation
To install the firmware tools, use the following command:
```
# lsof required
sudo yum install -y lsof
sudo yum install habanalabs-firmware-tools-1.1.1-94* -y
```

### (Optional) qual installation
To install hl_qual, use the following command:
```
sudo yum install habanalabs-qual-1.1.1-94* -y
```

### (Optional) aeon installation
To install aeon, use the following command:
```
sudo yum install habanalabs-aeon-1.1.1-94* -y
```
</details>
<details>
<summary>Amazon linux 2 distributions</summary>

Installing the package with internet connection available allows the network to download and install the required dependencies for the SyanapseAI® package (yum install and pip install etc.).

### Setup package fetching
1. Create this file: /etc/yum.repos.d/Habana-Vault.repo
2. Add the following content to the Habana-Vault.repo file:
```
[vault]

name=Habana Vault

baseurl=https://vault.habana.ai/artifactory/AmazonLinux2

enabled=1

gpgcheck=0

gpgkey=https://vault.habana.ai/artifactory/AmazonLinux2/repodata/repomod.xml.key

repo_gpgcheck=0
```
3. Update YUM cache by running the following command:
```
sudo yum makecache
```
4. Verify correct binding by running the following command:
```
yum search habana
```
This will search for and list all packages with the word Habana.

### Graph compiler and run-time installation
To install the graph compiler and run-time, use the following command:
```
sudo yum install habanalabs-graph-1.1.1-94* -y
```
### Thunk installation
To install the thunk library, use the following command:
```
sudo yum install habanalabs-thunk-1.1.1-94* -y
```
### Host firmware installation
Install the Firmware package:
```
sudo yum install habanalabs-firmware-1.1.1-94* -y
```
### (Optional) FW tools installation
To install the firmware tools, use the following command:
```
# lsof required
sudo yum install -y lsof
sudo yum install habanalabs-firmware-tools-1.1.1-94* -y
```

### (Optional) qual installation
To install hl_qual, use the following command:
```
sudo yum install habanalabs-qual-1.1.1-94* -y
```

### (Optional) aeon installation
To install aeon, use the following command:
```
sudo yum install habanalabs-aeon-1.1.1-94* -y
```
</details>
<br>

#### Update Environment Variables and More:
When the installation is complete, close the shell and re-open it. Or, run the following:
```
source /etc/profile.d/habanalabs.sh
source ~/.bashrc
```

<center>

### Please go back and check that the packages were installed
[Habana Software Package Check](#Check-Habana-Package-Installation-For-No-Docker)

</center>

<br />

---

<br />

## Check TF/Horovod Habana packages
Please ensure the following python packages are installed on your system:
* habana-tensorflow - Libraries and modules needed to execute TensorFlow on a single Gaudi device.
* habana-horovod - Libraries and modules needed to execute TensorFlow on an HLS machine.

### Setup Python Path
If the packages are installed, they are usually in the below supported python interpreters.  
Please setup the PYTHON variable before proceeding:
<details>
<summary>Ubuntu distributions</summary>

  * <details>
    <summary>Ubuntu 18.04</summary>
  
    Please run the following to set python variable
    ```
    export PYTHON=/usr/bin/python3.7
    ```
  
    </details>
  * <details>
    <summary>Ubuntu 20.04</summary>
  
    Please run the following to set python variable
    ```
    export PYTHON=/usr/bin/python3.8
    ```
    
  </details>
</details>
<details>
  <summary>CentOS/Amazon linux 2 distributions</summary>
  
  Please run the following to set python variable
  ```
  export PYTHON=/usr/bin/python3.7
  ```

</details>  
<br>

<table class="tg">
<thead>
  <tr>
    <th class="tg-tlu0"><span>OS</span></th>
    <th class="tg-4i2y" colspan="3">Python Version</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td class="tg-efrg">Ubuntu 18.04</td>
    <td class="tg-7jin" colspan="3">Python 3.7</td>
  </tr>
  <tr>
    <td class="tg-h418">Ubuntu 20.04</td>
    <td class="tg-yjv9" colspan="3">Python 3.8</td>
  </tr>
  <tr>
    <td class="tg-c1uv">Centos</td>
    <td class="tg-4p8a" colspan="3">Python 3.7</td>
  </tr>
  <tr>
    <td class="tg-po5t">Amazon Linux 2</td>
    <td class="tg-jp84" colspan="3">Python 3.7</td>
  </tr>
</tbody>
</table>

<br>

Use the following commands to fetch current python packages on the system:
```
${PYTHON} -m pip list | grep habana
```
Check for habana-tensorflow and habana-horovod 


<center>

### Are the required python packages installed on your system?
[Yes](#Setup-Complete) • [No](#install-tfhorovod-habana-packages)

</center>

<br />

---

<br />

## Install TF/Horovod Habana packages
This section describes how to obtain and install the TensorFlow software package. The package consists of two main components:  

Base **habana-tensorflow** Python package - Libraries and modules needed to execute TensorFlow on a **single Gaudi** device.  
Scale-out **habana-horovod** Python package - Libraries and modules needed to execute TensorFlow on **multiple Gaudi** devices.

<br />

---

<br />

The following example scripts include instructions from the steps [Base Installation (Single Node)](#Base-Installation-Single-Node) and [Scale-out Installation](#Scale-out-Installation) that can be used for your reference. The scripts install TF 2.6.2.
The scripts are using Python3 from ``/usr/bin/`` with version according to the [Support Matrix](#SynapseAi-Support-Matrix).  
Make sure, that Python3 is installed there, and if not, update the bash scripts with appropriate ``PYTHON=<path>``.

Ubuntu 18.04 example script [u18_tensorflow_installation.sh](https://github.com/HabanaAI/Setup_and_Install/blob/r1.1.1/installation_scripts/u18_tensorflow_installation.sh).

AmazonLinux2 example script [al2_tensorflow_installation.sh](https://github.com/HabanaAI/Setup_and_Install/blob/r1.1.1/installation_scripts/al2_tensorflow_installation.sh).

<br />

---

<br />

### Setup package fetching
<details>
<summary>Ubuntu distributions</summary>

* <details>
  <summary>Ubuntu 18.04</summary>

  ### Setup package fetching
  1. Download and install the public key:  
  ```
  curl -X GET https://vault.habana.ai/artifactory/api/gpg/key/public | sudo apt-key add -
  ```
  2. Create an apt source file /etc/apt/sources.list.d/artifactory.list
  3. Add the following content to the artifactory.list file:
  ```
  deb https://vault.habana.ai/artifactory/debian bionic main
  ```
  4. Update Debian cache:  
  ```
  sudo dpkg --configure -a
  sudo apt-get update
  ```  

  </details>
* <details>
  <summary>Ubuntu 20.04</summary>

  ### Setup package fetching
  1. Download and install the public key:  
  ```
  curl -X GET https://vault.habana.ai/artifactory/api/gpg/key/public | sudo apt-key add -
  ```
  2. Create an apt source file /etc/apt/sources.list.d/artifactory.list
  3. Add the following content to the artifactory.list file:
  ```
  deb https://vault.habana.ai/artifactory/debian focal main
  ```
  4. Update Debian cache:  
  ```
  sudo dpkg --configure -a
  sudo apt-get update
  ```  

  </details>
</details>

<details>
<summary>CentOS distributions</summary>

### Setup package fetching
1. Create this file: /etc/yum.repos.d/Habana-Vault.repo
2. Add the following content to the Habana-Vault.repo file:
```
[vault]

name=Habana Vault

baseurl=https://vault.habana.ai/artifactory/centos7

enabled=1

gpgcheck=0

gpgkey=https://vault.habana.ai/artifactory/centos7/repodata/repomod.xml.key

repo_gpgcheck=0
```
3. Update YUM cache by running the following command:
```
sudo yum makecache
```
4. Verify correct binding by running the following command:
```
yum search habana
```
This will search for and list all packages with the word Habana.

</details>
<details>
<summary>Amazon linux 2 distributions</summary>

### Setup package fetching
1. Create this file: /etc/yum.repos.d/Habana-Vault.repo
2. Add the following content to the Habana-Vault.repo file:
```
[vault]

name=Habana Vault

baseurl=https://vault.habana.ai/artifactory/AmazonLinux2

enabled=1

gpgcheck=0

gpgkey=https://vault.habana.ai/artifactory/AmazonLinux2/repodata/repomod.xml.key

repo_gpgcheck=0
```
3. Update YUM cache by running the following command:
```
sudo yum makecache
```
4. Verify correct binding by running the following command:
```
yum search habana
```
This will search for and list all packages with the word Habana.

</details>
<br>
<br>

### Base Installation (Single Node)
The habana-tensorflow package contains all the binaries and scripts to run topologies on a single-node.  

1. All the steps listed below are using to ``${PYTHON}`` environment variable, which must be set to appropriate version of Python, according to the version listed in [Support Matrix](#SynapseAi-Support-Matrix).  
```
export PYTHON=/usr/bin/python<VER> # i.e. for U18 it's PYTHON=/usr/bin/python3.7
```
2. Before installing habana-tensorflow, install supported TensorFlow version. See [Support Matrix](#SynapseAi-Support-Matrix). If no TensorFlow package is available, PIP will automatically fetch it.

```
${PYTHON} -m pip install --user tensorflow-cpu==<supported_tf_version>
```

<br>

#### Note:
Support for S3 file system (among others) has been moved to ``tensorflow-io``.
It needs to be installed separately and it has to be installed without its dependencies as it contains broken dependency on TF, that will cause PIP to install non-cpu ``tensorflow`` package.

```
# in case of installing TensorFlow 2.6.2
${PYTHON} -m pip install --user --no-deps tensorflow-io==0.21.0 tensorflow-io-gcs-filesystem==0.21.0

# in case of installing TensorFlow 2.7.0
${PYTHON} -m pip install --user --no-deps tensorflow-io==0.22.0 tensorflow-io-gcs-filesystem==0.22.0
```

<br>

3. habana-tensorflow is available in the Habana Vault. To allow PIP to search for the habana-tensorflow package, –extra-index-url needs to be specified:
```
${PYTHON} -m pip install --user habana-tensorflow==1.1.1.94 --extra-index-url https://vault.habana.ai/artifactory/api/pypi/gaudi-python/simple
```
4. Run the below command to make sure the habana-tensorflow package is properly installed:
```
${PYTHON} -c "import habana_frameworks.tensorflow as htf; print(htf.__version__)"
```
If everything is set up properly, the above command will print the currently installed package version.

<br>
<br>

#### Note: 
habana-tensorflow contains libraries for all supported TensorFlow versions. It is delivered under Linux tag, but the package is compatible with manylinux2010 tag (same as TensorFlow).
<br>
<br>

### Scale-out Installation
There are two methods of getting multi-node support - Horovod or TensorFlow distributed.

#### For Horovod Distributed:
Install the habana-horovod package to get multi-node support. The following lists the prerequisites for installing this package:

* OpenMPI 4.0.5.
* Stock horovod package must not be installed.

1. Install packages required to compile OpenMPI and Habana Horovod.   

  For Ubuntu 18:
  ```
  sudo apt install -y python3.7-dev
  sudo apt install -y wget
  ```
  For AmazonLinux2:
  ```
  sudo yum groupinstall -y "Development Tools"
  sudo yum install -y system-lsb-core cmake
  sudo yum install -y wget
  sudo yum install -y python3-devel
  ```

2. Set up the OpenMPI 4.0.5 as shown below:
  ```
  wget https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-4.0.5.tar.gz
  gunzip -c openmpi-4.0.5.tar.gz | tar xf -
  cd openmpi-4.0.5/ && sudo ./configure --prefix=/usr/local/share/openmpi
  sudo make -j 8 && sudo make install && touch ~root/openmpi-4.0.5_installed
  cp LICENSE /usr/local/share/openmpi/

  # Necessary env flags to install habana-horovod module
  export MPI_ROOT=/usr/local/share/openmpi
  export LD_LIBRARY_PATH=$MPI_ROOT/lib:$LD_LIBRARY_PATH
  export OPAL_PREFIX=$MPI_ROOT
  export PATH=$MPI_ROOT/bin:$PATH
  ```
  Install mpi4py binding
  ```
  ${PYTHON} -m pip install --user mpi4py==3.0.3
  ```
3. habana-horovod is also stored in the Habana Vault. To allow PIP to search for the habana-horovod package, –extra-index-url needs to be specified:
  ```
  ${PYTHON} -m pip install --user habana-horovod==1.1.1.94 --extra-index-url https://vault.habana.ai/artifactory/api/pypi/gaudi-python/simple
  ```

#### See also:
To learn more about the TensorFlow distributed training on Gaudi, see [Distributed Training with TensorFlow](https://docs.habana.ai/en/v1.1.1/Tensorflow_Scaling_Guide/TensorFlow_Gaudi_Scaling_Guide.html#distributed-training-with-tensorflow).
<br>
<br>

### Model references requirements
Habana provides a number of model references optimized to run on Gaudi. Those models are available in the [Model-References](https://github.com/HabanaAI/Model-References/tree/1.1.1/) page.  
Many of the references require additional 3rd party packages, not provided by Habana. This section describes how to install the required 3rd party packages.  
There are two types of packages required by the model references:
* System packages, installed with OS packet manager (e.g. apt in case of Ubuntu) There are three required system packages:
  * libjemalloc
  * protobuf-compiler
  * libGL
* Python packages, installed with pip tools

#### Installing System Packages

<details>
<summary>Ubuntu 18.04</summary>

```
sudo apt install -y libjemalloc1
sudo apt install -y protobuf-compiler
sudo apt install -y libgl1
```

#### Note: 
An example script for Ubuntu18 installing these OS packages is available for your reference: [u18_tensorflow_models_dependencies_installation.sh](https://github.com/HabanaAI/Setup_and_Install/blob/r1.1.1/installation_scripts/u18_tensorflow_models_dependencies_installation.sh)
<br>
<br>
</details>

<details>
<summary>Amazon linux 2 distributions</summary>

```
sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum install -y jemalloc
sudo yum install -y mesa-libGL
wget https://github.com/protocolbuffers/protobuf/releases/download/v3.6.1/protoc-3.6.1-linux-x86_64.zip
sudo unzip protoc-3.6.1-linux-x86_64.zip -d /usr/local/protoc
rm -rf protoc-3.6.1-linux-x86_64.zip
```

#### Note: 
An example script for AmazonLinux2 installing these OS packages is available for your reference: [al2_tensorflow_models_dependencies_installation.sh](https://github.com/HabanaAI/Setup_and_Install/blob/r1.1.1/installation_scripts/al2_tensorflow_models_dependencies_installation.sh)
<br>

</details>
<br>

#### Installing Python Packages

Python dependencies are gatehered in [model_requirements.txt](https://github.com/HabanaAI/Setup_and_Install/blob/r1.1.1/installation_scripts/model_requirements.txt)

Download the file and invoke:
```
${PYTHON} -m pip install --user -r model_requirements.txt
```

<br />

<center>

### Please go back and check that the packages were installed
[Check TF/Horovod Habana packages](#check-tfhorovod-habana-packages)

</center>

<br />

---

<br />

## Check PT Habana packages
Please ensure the following python packages are installed on your system:
* torch - PyTorch framework package with Habana support
* habana-torch - Libraries and modules needed to execute PyTorch on single card, single node and multi node setup.
* habana-dataloader - PyTorch Habana custom dataloader for ImageNet dataset.
* habana-torch-dataloader - Habana multi-threaded dataloader package.
* fairseq - Fairseq package updated with Habana support, required for Transformer model.
* transformers - Huggingface transformer package updated with Habana support, required for BERT Finetuning - SQuAD & MRPC.
* pytorch-lightning - PyTorch Lightning package with Habana support, required for Unet2D.

### Setup Python Path
If the packages are installed, they are usually in the below supported python interpreters.  
Please setup the PYTHON variable before proceeding:
<details>
<summary>Ubuntu distributions</summary>

  * <details>
    <summary>Ubuntu 18.04</summary>
  
    Please run the following to set python variable
    ```
    export PYTHON=/usr/bin/python3.7
    ```
  
    </details>
  * <details>
    <summary>Ubuntu 20.04</summary>
  
    Please run the following to set python variable
    ```
    export PYTHON=/usr/bin/python3.8
    ```
    
  </details>
</details>
<details>
  <summary>CentOS/Amazon linux 2 distributions</summary>
  
  Please run the following to set python variable
  ```
  export PYTHON=/usr/bin/python3.7
  ```

</details>  
<br>

<table class="tg">
<thead>
  <tr>
    <th class="tg-tlu0"><span>OS</span></th>
    <th class="tg-4i2y" colspan="3">Python Version</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td class="tg-efrg">Ubuntu 18.04</td>
    <td class="tg-7jin" colspan="3">Python 3.7</td>
  </tr>
  <tr>
    <td class="tg-h418">Ubuntu 20.04</td>
    <td class="tg-yjv9" colspan="3">Python 3.8</td>
  </tr>
  <tr>
    <td class="tg-c1uv">Centos</td>
    <td class="tg-4p8a" colspan="3">Python 3.7</td>
  </tr>
  <tr>
    <td class="tg-po5t">Amazon Linux 2</td>
    <td class="tg-jp84" colspan="3">Python 3.7</td>
  </tr>
</tbody>
</table>

<br>

Use the following commands to fetch current python packages on the system:
```
${PYTHON} -m pip list | grep habana
${PYTHON} -m pip list | grep fairseq
${PYTHON} -m pip list | grep transformers
${PYTHON} -m pip list | grep pytorch-lightning
```
Check for for the packages listed above

<center>

### Are the required python packages installed on your system?
[Yes](#Setup-Complete) • [No](#install-pt-habana-packages)

</center>

<br />

---

<br />

## Install PT Habana packages
### Install Habana Pytorch

1. Install the required packages:
  <details>
  <summary>Ubuntu distributions</summary>

  * <details>
    <summary>Ubuntu 18.04</summary>

    ```
    sudo apt-get install  -y unzip openssh-client curl libcurl4 moreutils iproute2 libcairo2-dev libglib2.0-dev libselinux1-dev libpcre2-dev libjpeg-dev
    sudo apt-get clean
    ```

    </details>
  * <details>
    <summary>Ubuntu 20.04</summary>

    Please run the following to install Habana Pytorch
    ```
    sudo apt-get install  -y unzip openssh-client curl libcurl4 moreutils iproute2 libcairo2-dev libglib2.0-dev libselinux1-dev libpcre2-dev libjpeg-dev
    sudo apt-get clean
    ```
    
    </details>
  </details>
  <details>
  <summary>Amazon linux 2 distributions</summary>

    Please run the following to install Habana Pytorch
    ```
    sudo yum install -y unzip openssh-clients openssh-server curl redhat-lsb-core openmpi-devel cairo-devel iproute git which libjpeg-devel zlib-devel
    sudo yum clean all
    ```

  </details>

2. Download and install OpenMPI and mpi4py package:
  ```
  export OPENMPI_VER=4.0.5
  wget --no-verbose https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-"${OPENMPI_VER}".tar.gz
  ```

  ```
  tar -xvf openmpi-"${OPENMPI_VER}".tar.gz
  cd openmpi-"${OPENMPI_VER}"
  ./configure --prefix="/usr/local/openmpi"
  make -j
  sudo make install
  sudo cp LICENSE /usr/local/openmpi
  cd –
  rm -rf openmpi-"${OPENMPI_VER}"*
  sudo /sbin/ldconfig
  export MPI_ROOT=/usr/local/openmpi
  export PATH=$MPI_ROOT/bin:$PATH
  ```

  ```
  MPICC=/usr/local/openmpi/bin/mpicc python -m pip install mpi4py==3.0.3 --no-cache-dir
  ```

3. Download and install the Python package. Download the tar ball file that will have the PyTorch specific packages from the [Habana Vault](https://vault.habana.ai/ui/repos/tree/General/gaudi-pt-modules). Ensure the following parameters are set prior to exercising the download command:
   * VERSION - Release version
   * REVISION - Build number
   * OS_NUMBER - Operating systems such as ubuntu2004, ubuntu1804, amzn2

    Refer to the [Support Matrix](https://docs.habana.ai/en/v1.1.1/Release_Notes/GAUDI_Release_Notes.html#support-matrix) to view the supported python version for each of the Operating Systems.
    ```
    wget https://vault.habana.ai/artifactory/gaudi-pt-modules/${VERSION}/${REVISION}/${OS_NUMBER}/binary/pytorch_modules-v1.9.1_${VERSION}_${REVISION}.tgz
    ```
    example:
    ```
    wget https://vault.habana.ai/artifactory/gaudi-pt-modules/1.1.1/94/ubuntu2004/binary/pytorch_modules-v1.9.1_1.1.1_94.tgz
    ```

4. Extract the tar ball:
  ```
  mkdir  habanalabs
  tar -xvf pytorch_modules-${VERSION}_${REVISION}.tgz -C habanalabs/
  ```
5. Install Habana PyTorch python packages:  
   All the steps listed below are using to ``${PYTHON}`` environment variable, which must be set to appropriate version of Python, according to [Support Matrix](#SynapseAi-Support-Matrix).  
   ```
   export PYTHON=/usr/bin/python<VER> # i.e. for U18 it's PYTHON=/usr/bin/python3.7
   ```
   Install ``torchvision`` and other packages using the requirement file. The torchvision installs ``torch`` package as a dependency. However, PyTorch uses an updated torch package with Habana support. To avoid having two torch packages uninstall the torch package.
  ```
  cd habanalabs
  ${PYTHON} -m pip install -r requirements-pytorch.txt
  ${PYTHON} -m pip uninstall torch -y
  ${PYTHON} -m pip install torch*.whl
  ${PYTHON} -m pip install habana_torch*.whl
  ${PYTHON} -m pip install habana_torch_dataloader*.whl
  ${PYTHON} -m pip install habana_dataloader*.whl
  ${PYTHON} -m pip install transformers*.whl
  ${PYTHON} -m pip install fairseq*.whl
  ${PYTHON} -m pip install pytorch_lightning*.whl
  ```
6. Uninstall pillow package and install pillow-simd:
  ```
  ${PYTHON} -m pip uninstall pillow
  ${PYTHON} -m pip install pillow-simd==7.0.0.post3
  ```
7. Update LD_LIBRARY_PATH path:
  ```
  LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/habanalabs:/usr/local/openmpi/lib
  ```

<br />

<center>

### Please go back and check that the packages were installed
[Check PT Habana packages](#Check-PT-Habana-packages)

</center>

<br />

---

<br />

<center>

### Do you want to use prebuilt docker or build docker yourself?
[Prebuilt](#Habana-Prebuilt-Containers-or-AWS-Deep-Learning-Containers) • [Build Docker](#How-to-Build-Docker-Images-from-Habana-Dockerfiles)

</center>


<br />

---

<br />

## How to Build Docker Images from Habana Dockerfiles
1. Download Docker files and build script from Github to local directory

2. Run build script to generate Docker image
```
./docker_build.sh mode [tensorflow,pytorch] os [ubuntu18.04,ubuntu20.04,amzn2,centos8.3,rhel8.3] tf_version [2.6.2, 2.7.0]
```
For example:
```
./docker_build.sh tensorflow ubuntu20.04 2.7.0
```

### Install habanalabs-container-runtime package
The Container Runtime is a modified [runc](https://github.com/opencontainers/runc) that installs the Container Runtime library.  This provides you the ability to select the devices to be mounted in the container.   With its help, you only need to specify the indices of the devices for the container, and the container runtime will handle the rest things properly. The container runtime can support both docker and kubernetes.

<details>
<summary>Ubuntu distributions</summary>

* <details>
  <summary>Ubuntu 18.04</summary>

  #### Setup package fetching
  1. Download and install the public key:  
  ```
  curl -X GET https://vault.habana.ai/artifactory/api/gpg/key/public | sudo apt-key add -
  ```
  2. Create an apt source file /etc/apt/sources.list.d/artifactory.list
  3. Add the following content to the artifactory.list file:
  ```
  deb https://vault.habana.ai/artifactory/debian bionic main
  ```
  4. Update Debian cache:  
  ```
  sudo dpkg --configure -a
  sudo apt-get update
  ```  
  #### Install habanalabs-container-runtime:
  Install the `habanalabs-container-runtime` package:
  ```
  sudo apt install -y habanalabs-container-runtime=1.1.1-94
  ```
  #### Docker Engine setup

  To register the `habana` runtime, use the method below that is best suited to your environment.
  You might need to merge the new argument with your existing configuration.

  ##### Daemon configuration file
  ```bash
  sudo tee /etc/docker/daemon.json <<EOF
  {
      "runtimes": {
          "habana": {
              "path": "/usr/bin/habana-container-runtime",
              "runtimeArgs": []
          }
      }
  }
  EOF
  sudo systemctl restart docker
  ```

  Optional: Reconfigure the default runtime by adding the following to `/etc/docker/daemon.json`:
  ```
  "default-runtime": "habana"
  ```
  It will look similar to this:
  ```
  {
      "default-runtime": "habana",
      "runtimes": {
          "habana": {
              "path": "/usr/bin/habana-container-runtime",
              "runtimeArgs": []
          }
      }
  }
  ```
  </details>

* <details>
  <summary>Ubuntu 20.04</summary>

  #### Setup package fetching
  1. Download and install the public key:  
  ```
  curl -X GET https://vault.habana.ai/artifactory/api/gpg/key/public | sudo apt-key add -
  ```
  2. Create an apt source file /etc/apt/sources.list.d/artifactory.list
  3. Add the following content to the artifactory.list file:
  ```
  deb https://vault.habana.ai/artifactory/debian focal main
  ```
  4. Update Debian cache:  
  ```
  sudo dpkg --configure -a
  sudo apt-get update
  ```  
  #### Install habanalabs-container-runtime:
  Install the `habanalabs-container-runtime` package:
  ```
  sudo apt install -y habanalabs-container-runtime=1.1.1-94
  ```
  #### Docker Engine setup

  To register the `habana` runtime, use the method below that is best suited to your environment.
  You might need to merge the new argument with your existing configuration.

  ##### Daemon configuration file
  ```bash
  sudo tee /etc/docker/daemon.json <<EOF
  {
      "runtimes": {
          "habana": {
              "path": "/usr/bin/habana-container-runtime",
              "runtimeArgs": []
          }
      }
  }
  EOF
  sudo systemctl restart docker
  ```

  Optional: Reconfigure the default runtime by adding the following to `/etc/docker/daemon.json`:
  ```
  "default-runtime": "habana"
  ```
  It will look similar to this:
  ```
  {
      "default-runtime": "habana",
      "runtimes": {
          "habana": {
              "path": "/usr/bin/habana-container-runtime",
              "runtimeArgs": []
          }
      }
  }
  ```
  </details>
</details>

<details>
<summary>CentOS distributions</summary>

#### Setup package fetching
1. Create this file: /etc/yum.repos.d/Habana-Vault.repo
2. Add the following content to the Habana-Vault.repo file:
```
[vault]

name=Habana Vault

baseurl=https://vault.habana.ai/artifactory/centos7

enabled=1

gpgcheck=0

gpgkey=https://vault.habana.ai/artifactory/centos7/repodata/repomod.xml.key

repo_gpgcheck=0
```
3. Update YUM cache by running the following command:
```
sudo yum makecache
```
4. Verify correct binding by running the following command:
```
yum search habana
```
This will search for and list all packages with the word Habana.

#### Install habanalabs-container-runtime:
Install the `habanalabs-container-runtime` package:
```
sudo yum install habanalabs-container-runtime-1.1.1-94* -y
```
#### Docker Engine setup

To register the `habana` runtime, use the method below that is best suited to your environment.
You might need to merge the new argument with your existing configuration.

##### Daemon configuration file
```bash
sudo tee /etc/docker/daemon.json <<EOF
{
    "runtimes": {
        "habana": {
            "path": "/usr/bin/habana-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF
sudo systemctl restart docker
```

Optional: Reconfigure the default runtime by adding the following to `/etc/docker/daemon.json`:
```
"default-runtime": "habana"
```
It will look similar to this:
```
{
    "default-runtime": "habana",
    "runtimes": {
        "habana": {
            "path": "/usr/bin/habana-container-runtime",
            "runtimeArgs": []
        }
    }
}
```
</details>

<details>
<summary>Amazon linux distributions</summary>

#### Setup package fetching
1. Create this file: /etc/yum.repos.d/Habana-Vault.repo
2. Add the following content to the Habana-Vault.repo file:
```
[vault]

name=Habana Vault

baseurl=https://vault.habana.ai/artifactory/AmazonLinux2

enabled=1

gpgcheck=0

gpgkey=https://vault.habana.ai/artifactory/AmazonLinux2/repodata/repomod.xml.key

repo_gpgcheck=0
```
3. Update YUM cache by running the following command:
```
sudo yum makecache
```
4. Verify correct binding by running the following command:
```
yum search habana
```
This will search for and list all packages with the word Habana.

#### Install habanalabs-container-runtime:
Install the `habanalabs-container-runtime` package:
```
sudo yum install habanalabs-container-runtime-1.1.1-94* -y
```
### Docker Engine setup

To register the `habana` runtime, use the method below that is best suited to your environment.
You might need to merge the new argument with your existing configuration.

#### Daemon configuration file
```bash
sudo tee /etc/docker/daemon.json <<EOF
{
    "runtimes": {
        "habana": {
            "path": "/usr/bin/habana-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF
sudo systemctl restart docker
```

Optional: Reconfigure the default runtime by adding the following to `/etc/docker/daemon.json`:
```
"default-runtime": "habana"
```
It will look similar to this:
```
{
    "default-runtime": "habana",
    "runtimes": {
        "habana": {
            "path": "/usr/bin/habana-container-runtime",
            "runtimeArgs": []
        }
    }
}
```
</details>
<br />

### Launch Docker image that was built
**NOTE:** Please download dataset prior to running docker and mount the location of your dataset to the docker by adding the below flag for example (Host dataset location `/opt/datasets/imagenet` will mount to `/datasets/imagenet` inside the docker):
```
-v /opt/datasets/imagenet:/datasets/imagenet
```
### Run docker command
**NOTE:** Modify below image name path $OS to match the OS chosen when building [ubuntu18.04,ubuntu20.04,amzn2]  
**NOTE:** Modify below image name path $MODE to match the mode chosen when building [tensorflow,pytorch]  
**NOTE:** Modify below image name path $TF_VERSION to match the TF version chosen when building [2.6.2, 2.7.0]  

TF:
```
docker run -it --runtime=habana -e HABANA_VISIBLE_DEVICES=all -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice --net=host vault.habana.ai/gaudi-docker/1.1.1/${OS}/habanalabs/tensorflow-installer-tf-cpu-${TF_VERSION}:1.1.1-94
```
PT:
```
docker run -it --runtime=habana -e HABANA_VISIBLE_DEVICES=all -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice --net=host --ipc=host vault.habana.ai/gaudi-docker/1.1.1/${OS}/habanalabs/pytorch-installer:1.1.1-94
```

**OPTIONAL:** Add the following flag to mount a local host share folder to the docker in order to be able to transfer files out of docker:

```
-v $HOME/shared:/root/shared
```

<br />

### Setup Python Path
The packages are installed in the below listed python interpreters.  
Please setup the PYTHON variable inside the docker if you would like to refer to the model-references:
<details>
<summary>Ubuntu distributions</summary>

  * <details>
    <summary>Ubuntu 18.04</summary>
  
    Please run the following to set python variable
    ```
    export PYTHON=/usr/bin/python3.7
    ```
  
    </details>
  * <details>
    <summary>Ubuntu 20.04</summary>
  
    Please run the following to set python variable
    ```
    export PYTHON=/usr/bin/python3.8
    ```
    
  </details>
</details>
<details>
  <summary>CentOS/Amazon linux 2 distributions</summary>
  
  Please run the following to set python variable
  ```
  export PYTHON=/usr/bin/python3.7
  ```

</details>  
<br>

<table class="tg">
<thead>
  <tr>
    <th class="tg-tlu0"><span>OS</span></th>
    <th class="tg-4i2y" colspan="3">Python Version</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td class="tg-efrg">Ubuntu 18.04</td>
    <td class="tg-7jin" colspan="3">Python 3.7</td>
  </tr>
  <tr>
    <td class="tg-h418">Ubuntu 20.04</td>
    <td class="tg-yjv9" colspan="3">Python 3.8</td>
  </tr>
  <tr>
    <td class="tg-c1uv">Centos</td>
    <td class="tg-4p8a" colspan="3">Python 3.7</td>
  </tr>
  <tr>
    <td class="tg-po5t">Amazon Linux 2</td>
    <td class="tg-jp84" colspan="3">Python 3.7</td>
  </tr>
</tbody>
</table>

<br>
<br>

<center>

Setup complete, please proceed to [Setup Complete](#Setup-Complete)

</center>

<br />

---

<br />

## Habana Prebuilt Containers or AWS Deep Learning Containers

### Use Habana Prebuilt Containers or AWS Deep Learning Containers?
[Habana Prebuilt Containers](#Habana-Prebuilt-Containers) • [AWS Deep Learning Containers](#AWS-Deep-Learning-Containers)

<br />

---

<br />

## Habana Prebuilt Containers

### Install habanalabs-container-runtime package
The Container Runtime is a modified [runc](https://github.com/opencontainers/runc) that installs the Container Runtime library.  This provides you the ability to select the devices to be mounted in the container.   With its help, you only need to specify the indices of the devices for the container, and the container runtime will handle the rest things properly. The container runtime can support both docker and kubernetes.

<details>
<summary>Ubuntu distributions</summary>

* <details>
  <summary>Ubuntu 18.04</summary>

  #### Setup package fetching
  1. Download and install the public key:  
  ```
  curl -X GET https://vault.habana.ai/artifactory/api/gpg/key/public | sudo apt-key add -
  ```
  2. Create an apt source file /etc/apt/sources.list.d/artifactory.list
  3. Add the following content to the artifactory.list file:
  ```
  deb https://vault.habana.ai/artifactory/debian bionic main
  ```
  4. Update Debian cache:  
  ```
  sudo dpkg --configure -a
  sudo apt-get update
  ```  
  #### Install habanalabs-container-runtime:
  Install the `habanalabs-container-runtime` package:
  ```
  sudo apt install -y habanalabs-container-runtime=1.1.1-94
  ```
  #### Docker Engine setup

  To register the `habana` runtime, use the method below that is best suited to your environment.
  You might need to merge the new argument with your existing configuration.

  ##### Daemon configuration file
  ```bash
  sudo tee /etc/docker/daemon.json <<EOF
  {
      "runtimes": {
          "habana": {
              "path": "/usr/bin/habana-container-runtime",
              "runtimeArgs": []
          }
      }
  }
  EOF
  sudo systemctl restart docker
  ```

  Optional: Reconfigure the default runtime by adding the following to `/etc/docker/daemon.json`:
  ```
  "default-runtime": "habana"
  ```
  It will look similar to this:
  ```
  {
      "default-runtime": "habana",
      "runtimes": {
          "habana": {
              "path": "/usr/bin/habana-container-runtime",
              "runtimeArgs": []
          }
      }
  }
  ```
  </details>

* <details>
  <summary>Ubuntu 20.04</summary>

  #### Setup package fetching
  1. Download and install the public key:  
  ```
  curl -X GET https://vault.habana.ai/artifactory/api/gpg/key/public | sudo apt-key add -
  ```
  2. Create an apt source file /etc/apt/sources.list.d/artifactory.list
  3. Add the following content to the artifactory.list file:
  ```
  deb https://vault.habana.ai/artifactory/debian focal main
  ```
  4. Update Debian cache:  
  ```
  sudo dpkg --configure -a
  sudo apt-get update
  ```  
  #### Install habanalabs-container-runtime:
  Install the `habanalabs-container-runtime` package:
  ```
  sudo apt install -y habanalabs-container-runtime=1.1.1-94
  ```
  #### Docker Engine setup

  To register the `habana` runtime, use the method below that is best suited to your environment.
  You might need to merge the new argument with your existing configuration.

  ##### Daemon configuration file
  ```bash
  sudo tee /etc/docker/daemon.json <<EOF
  {
      "runtimes": {
          "habana": {
              "path": "/usr/bin/habana-container-runtime",
              "runtimeArgs": []
          }
      }
  }
  EOF
  sudo systemctl restart docker
  ```

  Optional: Reconfigure the default runtime by adding the following to `/etc/docker/daemon.json`:
  ```
  "default-runtime": "habana"
  ```
  It will look similar to this:
  ```
  {
      "default-runtime": "habana",
      "runtimes": {
          "habana": {
              "path": "/usr/bin/habana-container-runtime",
              "runtimeArgs": []
          }
      }
  }
  ```
  </details>
</details>

<details>
<summary>CentOS distributions</summary>

#### Setup package fetching
1. Create this file: /etc/yum.repos.d/Habana-Vault.repo
2. Add the following content to the Habana-Vault.repo file:
```
[vault]

name=Habana Vault

baseurl=https://vault.habana.ai/artifactory/centos7

enabled=1

gpgcheck=0

gpgkey=https://vault.habana.ai/artifactory/centos7/repodata/repomod.xml.key

repo_gpgcheck=0
```
3. Update YUM cache by running the following command:
```
sudo yum makecache
```
4. Verify correct binding by running the following command:
```
yum search habana
```
This will search for and list all packages with the word Habana.

#### Install habanalabs-container-runtime:
Install the `habanalabs-container-runtime` package:
```
sudo yum install habanalabs-container-runtime-1.1.1-94* -y
```
#### Docker Engine setup

To register the `habana` runtime, use the method below that is best suited to your environment.
You might need to merge the new argument with your existing configuration.

##### Daemon configuration file
```bash
sudo tee /etc/docker/daemon.json <<EOF
{
    "runtimes": {
        "habana": {
            "path": "/usr/bin/habana-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF
sudo systemctl restart docker
```

Optional: Reconfigure the default runtime by adding the following to `/etc/docker/daemon.json`:
```
"default-runtime": "habana"
```
It will look similar to this:
```
{
    "default-runtime": "habana",
    "runtimes": {
        "habana": {
            "path": "/usr/bin/habana-container-runtime",
            "runtimeArgs": []
        }
    }
}
```
</details>

<details>
<summary>Amazon linux distributions</summary>

#### Setup package fetching
1. Create this file: /etc/yum.repos.d/Habana-Vault.repo
2. Add the following content to the Habana-Vault.repo file:
```
[vault]

name=Habana Vault

baseurl=https://vault.habana.ai/artifactory/AmazonLinux2

enabled=1

gpgcheck=0

gpgkey=https://vault.habana.ai/artifactory/AmazonLinux2/repodata/repomod.xml.key

repo_gpgcheck=0
```
3. Update YUM cache by running the following command:
```
sudo yum makecache
```
4. Verify correct binding by running the following command:
```
yum search habana
```
This will search for and list all packages with the word Habana.

#### Install habanalabs-container-runtime:
Install the `habanalabs-container-runtime` package:
```
sudo yum install habanalabs-container-runtime-1.1.1-94* -y
```
### Docker Engine setup

To register the `habana` runtime, use the method below that is best suited to your environment.
You might need to merge the new argument with your existing configuration.

#### Daemon configuration file
```bash
sudo tee /etc/docker/daemon.json <<EOF
{
    "runtimes": {
        "habana": {
            "path": "/usr/bin/habana-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF
sudo systemctl restart docker
```

Optional: Reconfigure the default runtime by adding the following to `/etc/docker/daemon.json`:
```
"default-runtime": "habana"
```
It will look similar to this:
```
{
    "default-runtime": "habana",
    "runtimes": {
        "habana": {
            "path": "/usr/bin/habana-container-runtime",
            "runtimeArgs": []
        }
    }
}
```
</details>
<br />

### Pull and launch Docker image
**NOTE:** Please download dataset prior to running docker and mount the location of your dataset to the docker by adding the below flag for example (Host dataset location `/opt/datasets/imagenet` will mount to `/datasets/imagenet` inside the docker):
```
-v /opt/datasets/imagenet:/datasets/imagenet
```

### Pull and Run commands

<details>
<summary>Ubuntu 20.04</summary>

* <details>
  <summary>TF 2.7.0</summary>

  ### Pull docker
  ```
  docker pull vault.habana.ai/gaudi-docker/1.1.1/ubuntu20.04/habanalabs/tensorflow-installer-tf-cpu-2.7.0:1.1.1-94
  ```
  ### Run docker
  ```
  docker run -it --runtime=habana -e HABANA_VISIBLE_DEVICES=all -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice --net=host vault.habana.ai/gaudi-docker/1.1.1/ubuntu20.04/habanalabs/tensorflow-installer-tf-cpu-2.7.0:1.1.1-94
  ```
  **NOTE:** Once inside the docker, run the following if you would like to use firmware tools:
  ```
  sudo apt install -y lsof
  ```

  </details>
* <details>
  <summary>TF 2.6.2</summary>

  ### Pull docker
  ```
  docker pull vault.habana.ai/gaudi-docker/1.1.1/ubuntu20.04/habanalabs/tensorflow-installer-tf-cpu-2.6.2:1.1.1-94
  ```
  ### Run docker
  ```
  docker run -it --runtime=habana -e HABANA_VISIBLE_DEVICES=all -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice --net=host vault.habana.ai/gaudi-docker/1.1.1/ubuntu20.04/habanalabs/tensorflow-installer-tf-cpu-2.6.2:1.1.1-94
  ```
  **NOTE:** Once inside the docker, run the following if you would like to use firmware tools:
  ```
  sudo apt install -y lsof
  ```

  </details>
* <details>
  <summary>Pytorch</summary>

  ### Pull docker
  ```
  docker pull vault.habana.ai/gaudi-docker/1.1.1/ubuntu20.04/habanalabs/pytorch-installer:1.1.1-94
  ```
  ### Run docker
  ```
  docker run -it --runtime=habana -e HABANA_VISIBLE_DEVICES=all -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice --net=host --ipc=host vault.habana.ai/gaudi-docker/1.1.1/ubuntu20.04/habanalabs/pytorch-installer:1.1.1-94
  ```

  </details>
</details>

<details>
<summary>Ubuntu 18.04</summary>

* <details>
  <summary>TF 2.7.0</summary>

  ### Pull docker  
  ```
  docker pull vault.habana.ai/gaudi-docker/1.1.1/ubuntu18.04/habanalabs/tensorflow-installer-tf-cpu-2.7.0:1.1.1-94
  ```
  ### Run docker
  ```
  docker run -it --runtime=habana -e HABANA_VISIBLE_DEVICES=all -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice --net=host vault.habana.ai/gaudi-docker/1.1.1/ubuntu18.04/habanalabs/tensorflow-installer-tf-cpu-2.7.0:1.1.1-94
  ```
  **NOTE:** Once inside the docker, run the following if you would like to use firmware tools:
  ```
  sudo apt install -y lsof
  ```

  </details>
* <details>
  <summary>TF 2.6.2</summary>

  ### Pull docker
  ```
  docker pull vault.habana.ai/gaudi-docker/1.1.1/ubuntu18.04/habanalabs/tensorflow-installer-tf-cpu-2.6.2:1.1.1-94
  ```
  ### Run docker
  ```
  docker run -it --runtime=habana -e HABANA_VISIBLE_DEVICES=all -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice --net=host vault.habana.ai/gaudi-docker/1.1.1/ubuntu18.04/habanalabs/tensorflow-installer-tf-cpu-2.6.2:1.1.1-94
  ```
  **NOTE:** Once inside the docker, run the following if you would like to use firmware tools:
  ```
  sudo apt install -y lsof
  ```

  </details>
* <details>
  <summary>Pytorch</summary>

  ### Pull docker
  ```
  docker pull vault.habana.ai/gaudi-docker/1.1.1/ubuntu18.04/habanalabs/pytorch-installer:1.1.1-94
  ```
  ### Run docker
  ```
  docker run -it --runtime=habana -e HABANA_VISIBLE_DEVICES=all -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice --net=host --ipc=host vault.habana.ai/gaudi-docker/1.1.1/ubuntu18.04/habanalabs/pytorch-installer:1.1.1-94
  ```

  </details>
</details>

<details>
<summary>Amazon Linux 2</summary>

* <details>
  <summary>TF 2.7.0</summary>
 
  ### Pull docker 
  ```
  docker pull vault.habana.ai/gaudi-docker/1.1.1/amzn2/habanalabs/tensorflow-installer-tf-cpu-2.7.0:1.1.1-94
  ```
  ### Run docker
  ```
  docker run -it --runtime=habana -e HABANA_VISIBLE_DEVICES=all -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice --net=host vault.habana.ai/gaudi-docker/1.1.1/amzn2/habanalabs/tensorflow-installer-tf-cpu-2.7.0:1.1.1-94
  ```
  **NOTE:** Once inside the docker, run the following if you would like to use firmware tools:
  ```
  sudo yum install -y lsof
  ```

  </details>
* <details>
  <summary>TF 2.6.2</summary>

  ### Pull docker
  ```
  docker pull vault.habana.ai/gaudi-docker/1.1.1/amzn2/habanalabs/tensorflow-installer-tf-cpu-2.6.2:1.1.1-94
  ```
  ### Run docker
  ```
  docker run -it --runtime=habana -e HABANA_VISIBLE_DEVICES=all -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice --net=host vault.habana.ai/gaudi-docker/1.1.1/amzn2/habanalabs/tensorflow-installer-tf-cpu-2.6.2:1.1.1-94
  ```
  **NOTE:** Once inside the docker, run the following if you would like to use firmware tools:
  ```
  sudo yum install -y lsof
  ```

  </details>
* <details>
  <summary>Pytorch</summary>

  ### Pull docker
  ```
  docker pull vault.habana.ai/gaudi-docker/1.1.1/amzn2/habanalabs/pytorch-installer:1.1.1-94
  ```
  ### Run docker
  ```
  docker run -it --runtime=habana -e HABANA_VISIBLE_DEVICES=all -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice --net=host --ipc=host vault.habana.ai/gaudi-docker/1.1.1/amzn2/habanalabs/pytorch-installer:1.1.1-94
  ```

  </details>
</details>

**OPTIONAL:** Add the following flag to mount a local host share folder to the docker in order to be able to transfer files out of docker:

```
-v $HOME/shared:/root/shared
```

<br />

### Setup Python Path
The packages are installed in the below listed python interpreters.  
Please setup the PYTHON variable inside the docker if you would like to refer to the model-references:
<details>
<summary>Ubuntu distributions</summary>

  * <details>
    <summary>Ubuntu 18.04</summary>
  
    Please run the following to set python variable
    ```
    export PYTHON=/usr/bin/python3.7
    ```
  
    </details>
  * <details>
    <summary>Ubuntu 20.04</summary>
  
    Please run the following to set python variable
    ```
    export PYTHON=/usr/bin/python3.8
    ```
    
  </details>
</details>
<details>
  <summary>CentOS/Amazon linux 2 distributions</summary>
  
  Please run the following to set python variable
  ```
  export PYTHON=/usr/bin/python3.7
  ```

</details>  
<br>

<table class="tg">
<thead>
  <tr>
    <th class="tg-tlu0"><span>OS</span></th>
    <th class="tg-4i2y" colspan="3">Python Version</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td class="tg-efrg">Ubuntu 18.04</td>
    <td class="tg-7jin" colspan="3">Python 3.7</td>
  </tr>
  <tr>
    <td class="tg-h418">Ubuntu 20.04</td>
    <td class="tg-yjv9" colspan="3">Python 3.8</td>
  </tr>
  <tr>
    <td class="tg-c1uv">Centos</td>
    <td class="tg-4p8a" colspan="3">Python 3.7</td>
  </tr>
  <tr>
    <td class="tg-po5t">Amazon Linux 2</td>
    <td class="tg-jp84" colspan="3">Python 3.7</td>
  </tr>
</tbody>
</table>

<br>
<br>

<center>

Setup complete, please proceed to [Setup Complete](#Setup-Complete)

</center>

<br />

---

<br />

## AWS Deep Learning Containers

Please refer to the following instructions on how to setup and use AWS Deep Learning Containers:
[AWS Available Deep Learning Containers Images](https://github.com/aws/deep-learning-containers/blob/master/available_images.md#habana-training-containers)


### Setup Python Path
The packages are installed in the below listed python interpreters.  
Please setup the PYTHON variable inside the docker if you would like to refer to the model-references:
<details>
<summary>Ubuntu distributions</summary>

  * <details>
    <summary>Ubuntu 18.04</summary>
  
    Please run the following to set python variable
    ```
    export PYTHON=/usr/bin/python3.7
    ```
  
    </details>
  * <details>
    <summary>Ubuntu 20.04</summary>
  
    Please run the following to set python variable
    ```
    export PYTHON=/usr/bin/python3.8
    ```
    
  </details>
</details>
<details>
  <summary>CentOS/Amazon linux 2 distributions</summary>
  
  Please run the following to set python variable
  ```
  export PYTHON=/usr/bin/python3.7
  ```

</details>  
<br>

<table class="tg">
<thead>
  <tr>
    <th class="tg-tlu0"><span>OS</span></th>
    <th class="tg-4i2y" colspan="3">Python Version</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td class="tg-efrg">Ubuntu 18.04</td>
    <td class="tg-7jin" colspan="3">Python 3.7</td>
  </tr>
  <tr>
    <td class="tg-h418">Ubuntu 20.04</td>
    <td class="tg-yjv9" colspan="3">Python 3.8</td>
  </tr>
  <tr>
    <td class="tg-c1uv">Centos</td>
    <td class="tg-4p8a" colspan="3">Python 3.7</td>
  </tr>
  <tr>
    <td class="tg-po5t">Amazon Linux 2</td>
    <td class="tg-jp84" colspan="3">Python 3.7</td>
  </tr>
</tbody>
</table>

<br>
<br>


<br />

<center>

Setup complete, please proceed to [Setup Complete](#Setup-Complete)

</center>

<br />

---

<br />

## Setup Complete
Congratulations! Your system should now be setup and ready to run models!

If you would like, you can refer to our Model-References Github pages for references models and how to run them.   
Tensorflow:  
[Model References Tensorflow](https://github.com/HabanaAI/Model-References/tree/1.1.1/TensorFlow)  
For Pytorch:  
[Model References Pytorch](https://github.com/HabanaAI/Model-References/tree/1.1.1/PyTorch)

<br />

---

<br />

## Additional setup checks
This section will provide some commands to help verify the software installation/update has been done properly

### Check habana module
```
lsmod | grep habana
```
After running the command, a driver called habanalabs should be displayed.
```
habanalabs 1204224 2
```

### Docker device check
After launching docker please use the following to ensure you can see your devices:
```
ls /dev
```
Expected output should include devices that were mounted to the docker (8 card example):
```
hl2   hl5  hl_controlD0       hl_controlD3  hl_controlD6
hl0   hl3  hl6  hl_controlD1  hl_controlD4  hl_controlD7
hl1   hl4  hl7  hl_controlD2  hl_controlD5
```

### PCI Cards Connected
Check that all the cards show up by running the following command:
```
sudo lspci -tvvv | grep 1da3
```
OR
```
sudo lspci -tvvv | grep Habana
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
This section requires hl-smi to be used, please refer to [this](#Install-SW-Stack) section on how to install hl-smi (Contained in habanalabs-firmware-tools package).  
Check all of the card's FW versions by running the following commands:
```
sudo hl-smi -q | grep FIT
sudo hl-smi -q | grep SPI
```
You should see the FIT version for each of the cards installed.  
Make sure the version matches what is expected (matching the release version you installed)

### Gaudi Clock Freq
This section requires hl-smi to be used, please refer to [this](#Install-SW-Stack) section on how to install hl-smi (Contained in habanalabs-firmware-tools package).  
Check all of the card's frequencies by running the following command:
```
sudo hl-smi -q | grep -A 1 'Clocks$'
```
This will list each card's frequency. Please make sure they are set as expected.

### habanalabs-qual
For some qualification tests, please refer to the following document on how to run and use habanalabs-qual:  
[GAUDI_Qualification_Library](https://docs.habana.ai/en/v1.1.1/Qualification_Library/GAUDI_Qualification_Library.html)

### CPU Performance Settings
Check that the CPU setting are set to performance:
```
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```
If not, set CPU setting to Performance:
```
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

<br />

---

<br />

## Additional links
For any additional information about installation, please refer to the following link:  
[Installation Guide](https://docs.habana.ai/en/v1.1.1/Installation_Guide/GAUDI_Installation_Guide.html)

For any additional debugging assistance, please refer to the following link:  
[Debugging Guide](https://docs.habana.ai/en/v1.1.1/Debugging_Guide/Debugging_Guide.html)

<br />

---

<br />

## Additional scripts and add-ons
### manage_network_ifs.sh
This script is used to bring up, take down, set IPs, unset IPs and check for status of the Gaudi network interfaces.

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

Note: Please run this script with one operation at a time
```
### Operations
Before executing any operation, this script finds all the Habana network interfaces available on the system and stores the Habana interface information into a list.  
The list will be used for the operations. If no Habana network interface is found, the script will exit. 

#### Up
Use the following command to bring all Habana network interfaces online:
```
sudo manage_network_ifs.sh --up
```
Once all the Habana interfaces are toggled up, IPs will be set by default. Please refer [Set Ip](#set-ip) for more detail. To unset IPs, run this script with '--unset-ip'
#### Down
Use the following command to bring all Habana network interfaces offline:
```
sudo manage_network_ifs.sh --down
```
#### Status
Print the current operational state of all Habana network interfaces such as how many ports are up/down:
```
sudo manage_network_ifs.sh --status
```
#### Set IP
Use the following command to assign a default IP for all Habana network interfaces:
```
sudo manage_network_ifs.sh --set-ip
```
Note: Default IPs are 192.168.100.1, 192.168.100.2, 192.168.100.3 and so on
#### Unset IP
Remove IP from all available Habana network interfaces by the following command:
```
sudo manage_network_ifs.sh --unset-ip
```
