# Gaudi Setup and Installation

## Table of Contents
  - [Overview](#overview)
  - [Setup Python](#setup-python)
  - [Cloud](#cloud)
  - [On Premises](#on-premises)
    - [Install Habana Driver](#install-habana-driver)
    - [Set number of huge pages](#set-number-of-huge-pages)
    - [Bring up network interfaces](#bring-up-network-interfaces)
    - [Will you be using Docker?](#will-you-be-using-docker)
      - No Docker
        - [Check Habana Package Installation for no Docker](#check-habana-package-installation-for-no-docker)
        - [Install SW Stack](#install-sw-stack)
        - [Check TF/Horovod Habana packages](#check-tfhorovod-habana-packages)
        - [Install TF/Horovod Habana python packages](#install-tfhorovod-habana-python-packages)
        - [Check PT Habana packages](#check-pt-habana-packages)
        - [Install PT Habana python packages](#install-pt-habana-python-packages)
      - Docker
        - [Do you want to use prebuilt docker or build docker yourself?](#do-you-want-to-use-prebuilt-docker-or-build-docker-yourself)
        - [How to Build Docker Images from Habana Dockerfiles](#how-to-build-docker-images-from-habana-dockerfiles)
        - [Pull prebuilt Docker image](#pull-prebuilt-docker-image)
  - [Run Reference Models](#run-reference-models)
  - [Additional setup checks](#additional-setup-checks)
  - [Additional links](#additional-links)
  - [Additional scripts and add-ons](#additional-scripts-and-add-ons)

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
<table class="tg">
<thead>
  <tr>
    <th class="tg-tlu0"><span style="font-weight:700;color:#FFF;background-color:#0079BB">SynapseAI</span></th>
    <th class="tg-4i2y" colspan="3"><span style="font-weight:700">1.0.0</span></th>
    <th class="tg-4i2y" colspan="3"><span style="font-weight:700">0.15.4</span></th>
  </tr>
</thead>
<tbody>
  <tr>
    <td class="tg-efrg"><span style="font-weight:700">Gaudi Firmware</span></td>
    <td class="tg-7jin" colspan="3">0.14.10</td>
    <td class="tg-7jin" colspan="3">0.14.10</td>
  </tr>
  <tr>
    <td class="tg-h418"><span style="font-weight:700">Gaudi SPI Firmware</span></td>
    <td class="tg-yjv9" colspan="3">0.14.10</td>
    <td class="tg-yjv9" colspan="3">0.14.10</td>
  </tr>
  <tr>
    <td class="tg-efrg"><span style="font-weight:700">Operating System</span></td>
    <td class="tg-s1ry"><span style="font-weight:700">Ubuntu</span></td>
    <td class="tg-s1ry"><span style="font-weight:700">Ubuntu</span></td>
    <td class="tg-s1ry"><span style="font-weight:700">Amazon Linux 2</span></td>
    <td class="tg-s1ry"><span style="font-weight:700">Ubuntu</span></td>
    <td class="tg-sm4r"><span style="font-weight:700">Ubuntu</span></td>
    <td class="tg-sm4r"><span style="font-weight:700">Amazon Linux 2</span></td>
  </tr>
  <tr>
    <td class="tg-60od">Version</td>
    <td class="tg-jp84">20.04</td>
    <td class="tg-jp84">18.04</td>
    <td class="tg-jp84"></td>
    <td class="tg-jp84">20.04</td>
    <td class="tg-jp84">18.04</td>
    <td class="tg-jp84"></td>
  </tr>
  <tr>
    <td class="tg-u1vx">Kernel</td>
    <td class="tg-4p8a">5.4.0 and above</td>
    <td class="tg-4p8a">4.15 and above</td>
    <td class="tg-4p8a">5.4.0 and above</td>
    <td class="tg-4p8a">5.4.0 and above</td>
    <td class="tg-4p8a">4.15 and above</td>
    <td class="tg-4p8a">5.4.0 and above</td>
  </tr>
  <tr>
    <td class="tg-60od">Python</td>
    <td class="tg-jp84">3.8</td>
    <td class="tg-jp84">3.7</td>
    <td class="tg-jp84">3.7</td>
    <td class="tg-jp84">3.8</td>
    <td class="tg-jp84">3.7</td>
    <td class="tg-jp84">3.7</td>
  </tr>
  <tr>
    <td class="tg-c1uv"><span style="font-weight:700">Kubernetes</span></td>
    <td class="tg-4p8a" colspan="3">1.19.7</td>
    <td class="tg-4p8a" colspan="3">1.19.7</td>
  </tr>
  <tr>
    <td class="tg-po5t"><span style="font-weight:700">Docker</span></td>
    <td class="tg-jp84" colspan="3">18.09.0</td>
    <td class="tg-jp84" colspan="3">18.09.0</td>
  </tr>
  <tr>
    <td class="tg-c1uv"><span style="font-weight:700">PyTorch</span></td>
    <td class="tg-4p8a" colspan="3">1.8.1</td>
    <td class="tg-4p8a" colspan="3">1.7.1</td>
  </tr>
  <tr>
    <td class="tg-po5t"><span style="font-weight:700">TensorFlow</span></td>
    <td class="tg-jp84" colspan="3">2.5.0</td>
    <td class="tg-jp84" colspan="3">2.5.0 and 2.4.1</td>
  </tr>
</tbody>
</table>

<br>

<center>

### Please proceed to the first step of setting up to use the appropriate Python
[Setup Python](#Setup-Python)

</center>

<br />

---

<br />

## Setup Python
Both the setup process and the execution process expect the following when instructing run commands:
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
    <th class="tg-tlu0"><span style="background-color:#0079BB">OS</span></th>
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

### Are you using a Cloud computing instance or setting up an system on premises?
[Cloud](#Cloud) • [On Premises](#On-Premises)

</center>

<br />

---

<br />

## Cloud

Please follow the directions from your cloud service provider to setup your instance.  
If a Habana instance is selected from your cloud service provider, it will be already setup in most cases to run out of the box. 
<br />

<center>

Please proceed to [Run Reference Models](#Run-Reference-Models)

</center>

<br />

---

<br />

## On Premises

Please ensure the driver is installed on your system using the following command:
<details>
<summary>Ubuntu distributions</summary>

```
dpkg -l | grep habanalabs-dkms
```

</details>
<details>
<summary>CentOS/Amazon linux 2 distributions</summary>

```
rpm -qa | grep habanalabs
```

</details>
<br />

<center>

### Does the command above show the package installed?
[Yes (Set number of huge pages)](#Set-number-of-huge-pages) • [No (Install Habana Driver)](#Install-Habana-Driver)

</center>

<br />

---

<br />

## Install Habana Driver
<details>
<summary>Ubuntu distributions</summary>

* <details>
  <summary>Ubuntu 18.04</summary>

  ### Setup package fetching
  1. Download and install the public key:  
  ```
  curl -X GET https://vault.habana.ai/artifactory/api/gpg/key/public | sudo apt-key add -
  ```
  2. Create an apt source file /etc/apt/sources.list.d/artifactory.list.
  3. Add the following content to the file:
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

  ### Setup base drivers
  The **habanalabs-dkms_all** package installs both the habanalabs and habanalabs_en (Ethernet) drivers. If automation scripts are used, the scripts must be modified to load/unload both drivers.

  On kernels 5.12 and later, you can load/unload the two drivers in no specific order. On kernels below 5.12, the habanalabs_en driver must be loaded before the habanalabs driver and unloaded after the habanalabs driver.

  The below command installs both the habanalabs and habanalabs_en driver:

  1. Remove old packages habanalabs-dkms
  ```
  sudo dpkg -P habanalabs-dkms
  ```
  2. Download and install habanalabs-dkms
  ```
  sudo apt install -y habanalabs-dkms=1.0.0-532
  ```
  </details>
* <details>
  <summary>Ubuntu 20.04</summary>

  ### Setup package fetching
  1. Download and install the public key:  
  ```
  curl -X GET https://vault.habana.ai/artifactory/api/gpg/key/public | sudo apt-key add -
  ```
  2. Create an apt source file /etc/apt/sources.list.d/artifactory.list.
  3. Add the following content to the file:
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
  The **habanalabs-dkms_all** package installs both the habanalabs and habanalabs_en (Ethernet) drivers. If automation scripts are used, the scripts must be modified to load/unload both drivers.

  On kernels 5.12 and later, you can load/unload the two drivers in no specific order. On kernels below 5.12, the habanalabs_en driver must be loaded before the habanalabs driver and unloaded after the habanalabs driver.

  The below command installs both the habanalabs and habanalabs_en driver:

  1. Remove old packages habanalabs-dkms
  ```
  sudo dpkg -P habanalabs-dkms
  ```
  2. Download and install habanalabs-dkms
  ```
  sudo apt install -y habanalabs-dkms=1.0.0-532
  ```
  </details>
</details>

<details>
<summary>CentOS distributions</summary>

### Setup package fetching
1. Create /etc/yum.repos.d/Habana-Vault.repo.
2. Add the following content to the file:
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
sudo yum install kernel-devel
```
3. After kernel upgrade, please reboot your machine.

### Additional Dependencies
Add yum-utils:
```
sudo yum install -y sudo yum-utils
```  

### Setup base drivers
The **habanalabs-dkms_all** package installs both the habanalabs and habanalabs_en (Ethernet) drivers. If automation scripts are used, the scripts must be modified to load/unload both drivers.

On kernels 5.12 and later, you can load/unload the two drivers in no specific order. On kernels below 5.12, the habanalabs_en driver must be loaded before the habanalabs driver and unloaded after the habanalabs driver.

The below command installs both the habanalabs and habanalabs_en driver:

1. Remove the previous driver package:
```
sudo yum remove habanalabs*
```
2. Download and install new driver:
```
sudo yum install habanalabs-1.0.0-532* -y
```
</details>
<details>
<summary>Amazon linux 2 distributions</summary>

### Setup package fetching
1. Create /etc/yum.repos.d/Habana-Vault.repo.
2. Add the following content to the file:
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
sudo yum install kernel-devel
```
3. After kernel upgrade, please reboot your machine.

### Additional Dependencies
Add yum-utils:
```
sudo yum install -y sudo yum-utils
```  

### Setup base drivers
The **habanalabs-dkms_all** package installs both the habanalabs and habanalabs_en (Ethernet) drivers. If automation scripts are used, the scripts must be modified to load/unload both drivers.

On kernels 5.12 and later, you can load/unload the two drivers in no specific order. On kernels below 5.12, the habanalabs_en driver must be loaded before the habanalabs driver and unloaded after the habanalabs driver.

The below command installs both the habanalabs and habanalabs_en driver:

1. Remove the previous driver package:
```
sudo yum remove habanalabs*
```
2. Download and install new driver:
```
sudo yum install habanalabs-1.0.0-532* -y
```
</details>

<center>

### Please go back and check that driver was installed
[Habana Driver Check](#On-Premises)

</center>
<br />

---

<br />

## Set number of huge pages
Some training models use huge pages. It is recommended to set the number of huge pages as provided below:
```
#calculate number of huge pages
huge_pages_size=$(grep "^Hugepagesize:" /proc/meminfo | awk '{print $2}') 
huge_pages_memory=$((110 * 1024)) # convert to kB 
number_of_cores=$(lscpu | grep "^CPU(s):" | awk '{print $2}') 
total_huge_pages_memory=$(($huge_pages_memory * $number_of_cores * 2)) 
number_of_huge_pages=$(($total_huge_pages_memory / $huge_pages_size + 1)) 

#set current hugepages
sudo sysctl -w vm.nr_hugepages=$number_of_huge_pages
#Remove old entry if exists in sysctl.conf
sudo sed --in-place '/nr_hugepages/d' /etc/sysctl.conf
#Insert huge pages settings to persist
echo "vm.nr_hugepages=$number_of_huge_pages" | sudo tee -a /etc/sysctl.conf
```

<center>

### Please proceed to
[Bring up network interfaces](#Bring-up-network-interfaces)

</center>

<br />

---

<br />

## Bring up network interfaces
If training using multiple Gaudi cards please ensure the network interfaces are brought up.
These interfaces need to be brought up every time the kernel module is loaded or unloaded and reloaded.
To do so, please use the following command:
```
/opt/habanalabs/scripts/habanalabs/manage_network_ifs.sh --up
```
For more information please refer to [This](#manage_network_ifs.sh) section

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
Please ensure the following software packages are installed on your system:
### Required packages:
* habanalabs-dkms_all – installs the PCIe driver. (Should already be installed in previous steps)
* habanalabs-graph-_all – installs the Graph Compiler and the run-time.
* habanalabs-thunk-_all – installs the thunk library.
* habanalabs-firmware - installs the Gaudi Firmware.

### Optional packages:
* habanalabs-firmware-tools – installs various Firmware tools (hlml, hl-smi, etc).
* habanalabs-qual – installs the qualification application package. See See [Gaudi Qualification Library.](https://docs.habana.ai/en/latest/Qualification_Library/GAUDI_Qualification_Library.html)
* habanalabs-container-runtime - installs the container runtime library.
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

Installing the package with internet connection available allows the network to download and install the required dependencies for the SynapseAI package (apt get and pip install etc.).

* <details>
  <summary>Ubuntu 18.04</summary>

  ### Setup package fetching
  1. Download and install the public key:  
  ```
  curl -X GET https://vault.habana.ai/artifactory/api/gpg/key/public | sudo apt-key add -
  ```
  2. Create an apt source file /etc/apt/sources.list.d/artifactory.list.
  3. Add the following content to the file:
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
  sudo apt install -y habanalabs-graph=1.0.0-532
  ```
  ### Thunk installation
  To install the thunk library, use the following command:
  ```
  sudo apt install -y habanalabs-thunk=1.0.0-532
  ```
  ### Update FW
  Install the Firmware package:
  ```
  sudo apt install -y habanalabs-firmware=1.0.0-532
  ```
  ### (Optional) FW tools installation
  To install the firmware tools, use the following command:
  ```
  sudo apt install -y habanalabs-firmware-tools=1.0.0-532
  ```

  ### (Optional) qual installation
  To install hl_qual, use the following command:
  ```
  sudo apt install -y habanalabs-qual=1.0.0-532
  ```

  ### (Optional) aeon installation
  To install aeon, use the following command:
  ```
  sudo apt install -y habanalabs-aeon=1.0.0-532
  ```
  </details>
* <details>
  <summary>Ubuntu 20.04</summary>

  ### Setup package fetching
  1. Download and install the public key:  
  ```
  curl -X GET https://vault.habana.ai/artifactory/api/gpg/key/public | sudo apt-key add -
  ```
  2. Create an apt source file /etc/apt/sources.list.d/artifactory.list.
  3. Add the following content to the file:
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
  sudo apt install -y habanalabs-graph=1.0.0-532
  ```
  ### Thunk installation
  To install the thunk library, use the following command:
  ```
  sudo apt install -y habanalabs-thunk=1.0.0-532
  ```
  ### Update FW  
  Install the Firmware package:
  ```
  sudo apt install -y habanalabs-firmware=1.0.0-532
  ```
  ### (Optional) FW tools installation
  To install the firmware tools, use the following command:
  ```
  sudo apt install -y habanalabs-firmware-tools=1.0.0-532
  ```

  ### (Optional) qual installation
  To install hl_qual, use the following command:
  ```
  sudo apt install -y habanalabs-qual=1.0.0-532
  ```

  ### (Optional) aeon installation
  To install aeon, use the following command:
  ```
  sudo apt install -y habanalabs-aeon=1.0.0-532
  ```
  </details>
</details>

<details>
<summary>CentOS distributions</summary>

Installing the package with internet connection available allows the network to download and install the required dependencies for the SynapseAI package (yum install and pip install etc.).

### Setup package fetching
1. Create /etc/yum.repos.d/Habana-Vault.repo.
2. Add the following content to the file:
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
sudo yum install habanalabs-graph-1.0.0-532* -y
```
### Thunk installation
To install the thunk library, use the following command:
```
sudo yum install habanalabs-thunk-1.0.0-532* -y
```
### Update FW
Install the Firmware package:
```
sudo yum install habanalabs-firmware-1.0.0-532* -y
```
### (Optional) FW tools installation
To install the firmware tools, use the following command:
```
sudo yum install habanalabs-firmware-tools-1.0.0-532* -y
```

### (Optional) qual installation
To install hl_qual, use the following command:
```
sudo yum install habanalabs-qual-1.0.0-532* -y
```

### (Optional) aeon installation
To install aeon, use the following command:
```
sudo yum install habanalabs-aeon-1.0.0-532* -y
```
</details>
<details>
<summary>Amazon linux 2 distributions</summary>

Installing the package with internet connection available allows the network to download and install the required dependencies for the SynapseAI package (yum install and pip install etc.).

### Setup package fetching
1. Create /etc/yum.repos.d/Habana-Vault.repo.
2. Add the following content to the file:
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
sudo yum install habanalabs-graph-1.0.0-532* -y
```
### Thunk installation
To install the thunk library, use the following command:
```
sudo yum install habanalabs-thunk-1.0.0-532* -y
```
### Update FW
Install the Firmware package:
```
sudo yum install habanalabs-firmware-1.0.0-532* -y
```
### (Optional) FW tools installation
To install the firmware tools, use the following command:
```
sudo yum install habanalabs-firmware-tools-1.0.0-532* -y
```

### (Optional) qual installation
To install hl_qual, use the following command:
```
sudo yum install habanalabs-qual-1.0.0-532* -y
```

### (Optional) aeon installation
To install aeon, use the following command:
```
sudo yum install habanalabs-aeon-1.0.0-532* -y
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

Use the following commands to fetch current python packages on the system:
```
${PYTHON} -m pip list | grep habana
```


<center>

### Are the required python packages installed on your system?
[Yes](#Run-Reference-Models) • [No](#Install-TFHorovod-Habana-python-packages)

</center>

<br />

---

<br />

## Install TF/Horovod Habana python packages
This section describes how to obtain and install the TensorFlow software package. The package consists of two main components:  

Base **habana-tensorflow** Python package - Libraries and modules needed to execute TensorFlow on a **single Gaudi** device.  
Scale-out **habana-horovod** Python package - Libraries and modules needed to execute TensorFlow on **multiple Gaudi** devices.
### Base Installation (Single Node)
The habana-tensorflow package contains all the binaries and scripts to run topologies on a single-node.  

1. Before installing habana-tensorflow, install supported TensorFlow version. See [Support Matrix](#SynapseAi-Support-Matrix). If no TensorFlow package is available, PIP will automatically fetch it.
```
python3 -m pip install tensorflow-cpu==<supported_tf_version>
```

2. habana-tensorflow is available in the Habana Vault. To allow PIP to search for the habana-tensorflow package, –extra-index-url needs to be specified:
```
${PYTHON} -m pip install habana-tensorflow --extra-index-url https://vault.habana.ai/artifactory/api/pypi/gaudi-python/simple
```
3. Run the below command to make sure the habana-tensorflow package is properly installed:
```
${PYTHON} -c "import habana_frameworks.tensorflow as htf; print(htf.__version__)"
```
If everything is set up properly, the above command will print the currently installed package version.

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

1. Set up the OpenMPI 4.0.5 as shown below:
```
wget https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-4.0.5.tar.gz
gunzip -c openmpi-4.0.5.tar.gz | tar xf -
cd openmpi-4.0.5/ && ./configure --prefix=/usr/local/share/openmpi
make -j 8 && make install && touch ~root/openmpi-4.0.5_installed
cp LICENSE /usr/local/share/openmpi/

# Necessary env flags to install habana-horovod module
export MPI_ROOT=/usr/local/share/openmpi
export LD_LIBRARY_PATH=$MPI_ROOT/lib:$LD_LIBRARY_PATH
export OPAL_PREFIX=$MPI_ROOT
export PATH=$MPI_ROOT/bin:$PATH
```
2. habana-horovod is also stored in the Habana Vault. To allow PIP to search for the habana-horovod package, –extra-index-url needs to be specified:
```
${PYTHON} -m pip install habana-horovod --extra-index-url https://vault.habana.ai/artifactory/api/pypi/gaudi-python/simple
```

#### For TensorFlow Distributed:
To get scale-out capabilities on TensorFlow distributed, no additional packages other than **habana-tensorflow** package needs to be installed. Unlike Horovod, neither tf.distribute nor HPUStrategy use/require OpenMPI at any point. Worker processes can be initialized in any way. Refer to [Model References repository](https://github.com/HabanaAI/Model-References) for an example using mpirun, as it offers process-to-core binding mechanism. Installing OpenMPI as described above in [For Horovod Distributed](For-Horovod-Distributed) is recommended.

#### See also:
To learn more about the TensorFlow distributed training on Gaudi, see [Distributed Training with TensorFlow](https://docs.habana.ai/en/latest/Tensorflow_Scaling_Guide/TensorFlow_Gaudi_Scaling_Guide.html#distributed-training-with-tensorflow).

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
* Base Habana Pytorch package – libraries and modules needed to execute PyTorch on a single Gaudi device
* Distributed Habana Pytorch package - libraries and modules needed to execute PyTorch on an HLS machine

Use the following commands to fetch current python packages on the system:
```
${PYTHON} -m pip list | grep habana
```
Check for habana-torch and habana-torch-hcl

<center>

### Are the required python packages installed on your system?
[Yes](#Run-Reference-Models) • [No](#Install-PT-Habana-python-packages)

</center>

<br />

---

<br />

## Install PT Habana python packages
### Install Habana Pytorch
<details>
<summary>Ubuntu distributions</summary>

* <details>
  <summary>Ubuntu 18.04</summary>

  Please run the following to install Habana Pytorch
  ```
  wget https://vault.habana.ai/artifactory/gaudi-pt-modules/1.0.0/532/ubuntu1804/binary/pytorch_modules-1.0.0_532.tgz
  mkdir -p /root/habanalabs/pytorch_temp
  tar -xf pytorch_modules-1.0.0_532.tgz -C /root/habanalabs/pytorch_temp/.
  mv /root/habanalabs/pytorch_temp/*.so /usr/lib/habanalabs/
  ${PYTHON} -m pip install --no-cache-dir -r /root/habanalabs/pytorch_temp/requirements-pytorch.txt --no-warn-script-location
  ${PYTHON} -m pip uninstall --yes torch
  ${PYTHON} -m pip install /root/habanalabs/pytorch_temp/*.whl
  /sbin/ldconfig
  echo "source /etc/profile.d/habanalabs.sh" >> ~/.bashrc
  rm -rf /root/habanalabs/pytorch_temp/
  rm -rf pytorch_modules-1.0.0_532.tgz
  ```

  </details>
* <details>
  <summary>Ubuntu 20.04</summary>

  Please run the following to install Habana Pytorch
  ```
  wget https://vault.habana.ai/artifactory/gaudi-pt-modules/1.0.0/532/ubuntu2004/binary/pytorch_modules-1.0.0_532.tgz
  mkdir -p /root/habanalabs/pytorch_temp
  tar -xf pytorch_modules-1.0.0_532.tgz -C /root/habanalabs/pytorch_temp/.
  mv /root/habanalabs/pytorch_temp/*.so /usr/lib/habanalabs/
  ${PYTHON} -m pip install --no-cache-dir -r /root/habanalabs/pytorch_temp/requirements-pytorch.txt --no-warn-script-location
  ${PYTHON} -m pip uninstall --yes torch
  ${PYTHON} -m pip install /root/habanalabs/pytorch_temp/*.whl
  /sbin/ldconfig
  echo "source /etc/profile.d/habanalabs.sh" >> ~/.bashrc
  rm -rf /root/habanalabs/pytorch_temp/
  rm -rf pytorch_modules-1.0.0_532.tgz
  ```
  
  </details>
</details>
<details>
<summary>Amazon linux 2 distributions</summary>

  Please run the following to install Habana Pytorch
  ```
  wget https://vault.habana.ai/artifactory/gaudi-pt-modules/1.0.0/532/amzn2/binary/pytorch_modules-1.0.0_532.tgz
  mkdir -p /root/habanalabs/pytorch_temp
  tar -xf pytorch_modules-1.0.0_532.tgz -C /root/habanalabs/pytorch_temp/.
  mv /root/habanalabs/pytorch_temp/*.so /usr/lib/habanalabs/
  ${PYTHON} -m pip install --no-cache-dir -r /root/habanalabs/pytorch_temp/requirements-pytorch.txt --no-warn-script-location
  ${PYTHON} -m pip uninstall --yes torch
  ${PYTHON} -m pip install /root/habanalabs/pytorch_temp/*.whl
  /sbin/ldconfig
  echo "source /etc/profile.d/habanalabs.sh" >> ~/.bashrc
  rm -rf /root/habanalabs/pytorch_temp/
  rm -rf pytorch_modules-1.0.0_532.tgz
  ```

</details>

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
[Prebuilt](#Pull-prebuilt-Docker-image) • [Build Docker](#How-to-Build-Docker-Images-from-Habana-Dockerfiles)

</center>


<br />

---

<br />

## How to Build Docker Images from Habana Dockerfiles
1. Download Docker files and build script from Github to local directory

2. Run build script to generate Docker image
```
./docker_build.sh mode [base,tensorflow,pytorch] os [ubuntu18.04,ubuntu20.04,amzn2] tf_version [2.4.1, 2.5.0]
```
For example:
```
./docker_build.sh tensorflow ubuntu20.04 2.5.0
```

### Install habana-container-runtime package
<details>
<summary>Ubuntu distributions</summary>

* <details>
  <summary>Ubuntu 18.04</summary>

  #### Setup package fetching
  1. Download and install the public key:  
  ```
  curl -X GET https://vault.habana.ai/artifactory/api/gpg/key/public | sudo apt-key add -
  ```
  2. Create an apt source file /etc/apt/sources.list.d/artifactory.list.
  3. Add the following content to the file:
  ```
  deb https://vault.habana.ai/artifactory/debian bionic main
  ```
  4. Update Debian cache:  
  ```
  sudo dpkg --configure -a
  sudo apt-get update
  ```  
  #### Install habana-container-runtime:
  Install the `habana-container-runtime` package:
  ```
  sudo apt install -y habanalabs-container-runtime=1.0.0-532
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
  2. Create an apt source file /etc/apt/sources.list.d/artifactory.list.
  3. Add the following content to the file:
  ```
  deb https://vault.habana.ai/artifactory/debian focal main
  ```
  4. Update Debian cache:  
  ```
  sudo dpkg --configure -a
  sudo apt-get update
  ```  
  #### Install habana-container-runtime:
  Install the `habana-container-runtime` package:
  ```
  sudo apt install -y habanalabs-container-runtime=1.0.0-532
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
1. Create /etc/yum.repos.d/Habana-Vault.repo.
2. Add the following content to the file:
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

#### Install habana-container-runtime:
Install the `habana-container-runtime` package:
```
sudo yum install habanalabs-container-runtime-1.0.0-532* -y
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
1. Create /etc/yum.repos.d/Habana-Vault.repo.
2. Add the following content to the file:
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

#### Install habana-container-runtime:
Install the `habana-container-runtime` package:
```
sudo yum install habanalabs-container-runtime-1.0.0-532* -y
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
**NOTE:** Modify below image name path $MODE to match the mode chosen when building [base,tensorflow,pytorch]  
**NOTE:** Modify below image name path $TF_VERSION to match the TF version chosen when building [2.4.1, 2.5.0]  

Base:
```
docker run -it --runtime=habana -e HABANA_VISIBLE_DEVICES=all -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice --net=host vault.habana.ai/gaudi-docker/${SYNAPSE_BUILT_VERSION}/${OS}_${PYTHON_VERSION}/habanalabs/base-installer:${SYNAPSE_BUILT_VERSION}-${SYNAPSE_BUILT_REVISION}"
```
TF:
```
docker run -it --runtime=habana -e HABANA_VISIBLE_DEVICES=all -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice --net=host vault.habana.ai/gaudi-docker/${SYNAPSE_BUILT_VERSION}/${OS}/habanalabs/tensorflow-installer-tf-cpu-${TF_VERSION}:${SYNAPSE_BUILT_VERSION}-${SYNAPSE_BUILT_REVISION}
```
PT:
```
docker run -it --runtime=habana -e HABANA_VISIBLE_DEVICES=all -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice --net=host --ipc=host vault.habana.ai/gaudi-docker/${SYNAPSE_BUILT_VERSION}/${OS}/habanalabs/pytorch-installer:${SYNAPSE_BUILT_VERSION}-${SYNAPSE_BUILT_REVISION}
```

**OPTIONAL:** Add the following flag to mount a local host share folder to the docker in order to be able to transfer files out of docker:

```
-v $HOME/shared:/root/shared
```

<br />

<center>

Setup complete, please proceed to [Run Reference Models](#Run-Reference-Models)

</center>

<br />

---

<br />

## Pull prebuilt Docker image

### Install habana-container-runtime package
<details>
<summary>Ubuntu distributions</summary>

* <details>
  <summary>Ubuntu 18.04</summary>

  #### Setup package fetching
  1. Download and install the public key:  
  ```
  curl -X GET https://vault.habana.ai/artifactory/api/gpg/key/public | sudo apt-key add -
  ```
  2. Create an apt source file /etc/apt/sources.list.d/artifactory.list.
  3. Add the following content to the file:
  ```
  deb https://vault.habana.ai/artifactory/debian bionic main
  ```
  4. Update Debian cache:  
  ```
  sudo dpkg --configure -a
  sudo apt-get update
  ```  
  #### Install habana-container-runtime:
  Install the `habana-container-runtime` package:
  ```
  sudo apt install -y habanalabs-container-runtime=1.0.0-532
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
  2. Create an apt source file /etc/apt/sources.list.d/artifactory.list.
  3. Add the following content to the file:
  ```
  deb https://vault.habana.ai/artifactory/debian focal main
  ```
  4. Update Debian cache:  
  ```
  sudo dpkg --configure -a
  sudo apt-get update
  ```  
  #### Install habana-container-runtime:
  Install the `habana-container-runtime` package:
  ```
  sudo apt install -y habanalabs-container-runtime=1.0.0-532
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
1. Create /etc/yum.repos.d/Habana-Vault.repo.
2. Add the following content to the file:
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

#### Install habana-container-runtime:
Install the `habana-container-runtime` package:
```
sudo yum install habanalabs-container-runtime-1.0.0-532* -y
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
1. Create /etc/yum.repos.d/Habana-Vault.repo.
2. Add the following content to the file:
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

#### Install habana-container-runtime:
Install the `habana-container-runtime` package:
```
sudo yum install habanalabs-container-runtime-1.0.0-532* -y
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
  <summary>TF 2.4.1</summary>

  ### Pull docker
  ```
  docker pull vault.habana.ai/gaudi-docker/1.0.0/ubuntu20.04/habanalabs/tensorflow-installer-tf-cpu-2.4.1:1.0.0-532
  ```
  ### Run docker
  ```
  docker run -it --runtime=habana -e HABANA_VISIBLE_DEVICES=all -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice --net=host vault.habana.ai/gaudi-docker/1.0.0/ubuntu20.04/habanalabs/tensorflow-installer-tf-cpu-2.4.1:1.0.0-532
  ```

  </details>
* <details>
  <summary>TF 2.5.0</summary>

  ### Pull docker
  ```
  docker pull vault.habana.ai/gaudi-docker/1.0.0/ubuntu20.04/habanalabs/tensorflow-installer-tf-cpu-2.5.0:1.0.0-532
  ```
  ### Run docker
  ```
  docker run -it --runtime=habana -e HABANA_VISIBLE_DEVICES=all -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice --net=host vault.habana.ai/gaudi-docker/1.0.0/ubuntu20.04/habanalabs/tensorflow-installer-tf-cpu-2.5.0:1.0.0-532
  ```
* <details>
  <summary>Pytorch</summary>

  ### Pull docker
  ```
  docker pull vault.habana.ai/gaudi-docker/1.0.0/ubuntu20.04/habanalabs/pytorch-installer:1.0.0-532
  ```
  ### Run docker
  ```
  docker run -it --runtime=habana -e HABANA_VISIBLE_DEVICES=all -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice --net=host --ipc=host vault.habana.ai/gaudi-docker/1.0.0/ubuntu20.04/habanalabs/pytorch-installer:1.0.0-532
  ```

  </details>
</details>

<details>
<summary>Ubuntu 18.04</summary>

* <details>
  <summary>TF 2.4.1</summary>

  ### Pull docker  
  ```
  docker pull vault.habana.ai/gaudi-docker/1.0.0/ubuntu18.04/habanalabs/tensorflow-installer-tf-cpu-2.4.1:1.0.0-532
  ```
  ### Run docker
  ```
  docker run -it --runtime=habana -e HABANA_VISIBLE_DEVICES=all -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice --net=host vault.habana.ai/gaudi-docker/1.0.0/ubuntu18.04/habanalabs/tensorflow-installer-tf-cpu-2.4.1:1.0.0-532
  ```

  </details>
* <details>
  <summary>TF 2.5.0</summary>

  ### Pull docker
  ```
  docker pull vault.habana.ai/gaudi-docker/1.0.0/ubuntu18.04/habanalabs/tensorflow-installer-tf-cpu-2.5.0:1.0.0-532
  ```
  ### Run docker
  ```
  docker run -it --runtime=habana -e HABANA_VISIBLE_DEVICES=all -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice --net=host vault.habana.ai/gaudi-docker/1.0.0/ubuntu18.04/habanalabs/tensorflow-installer-tf-cpu-2.5.0:1.0.0-532
  ```

  </details>
* <details>
  <summary>Pytorch</summary>

  ### Pull docker
  ```
  docker pull vault.habana.ai/gaudi-docker/1.0.0/ubuntu18.04/habanalabs/pytorch-installer:1.0.0-532
  ```
  ### Run docker
  ```
  docker run -it --runtime=habana -e HABANA_VISIBLE_DEVICES=all -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice --net=host --ipc=host vault.habana.ai/gaudi-docker/1.0.0/ubuntu18.04/habanalabs/pytorch-installer:1.0.0-532
  ```

  </details>
</details>

<details>
<summary>Amazon Linux 2</summary>

* <details>
  <summary>TF 2.4.1</summary>
 
  ### Pull docker 
  ```
  docker pull vault.habana.ai/gaudi-docker/1.0.0/amzn2/habanalabs/tensorflow-installer-tf-cpu-2.4.1:1.0.0-532
  ```
  ### Run docker
  ```
  docker run -it --runtime=habana -e HABANA_VISIBLE_DEVICES=all -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice --net=host vault.habana.ai/gaudi-docker/1.0.0/amzn2/habanalabs/tensorflow-installer-tf-cpu-2.4.1:1.0.0-532
  ```

  </details>
* <details>
  <summary>TF 2.5.0</summary>

  ### Pull docker
  ```
  docker pull vault.habana.ai/gaudi-docker/1.0.0/amzn2/habanalabs/tensorflow-installer-tf-cpu-2.5.0:1.0.0-532
  ```
  ### Run docker
  ```
  docker run -it --runtime=habana -e HABANA_VISIBLE_DEVICES=all -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice --net=host vault.habana.ai/gaudi-docker/1.0.0/amzn2/habanalabs/tensorflow-installer-tf-cpu-2.5.0:1.0.0-532
  ```

  </details>
* <details>
  <summary>Pytorch</summary>

  ### Pull docker
  ```
  docker pull vault.habana.ai/gaudi-docker/1.0.0/amzn2/habanalabs/pytorch-installer:1.0.0-532
  ```
  ### Run docker
  ```
  docker run -it --runtime=habana -e HABANA_VISIBLE_DEVICES=all -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice --net=host --ipc=host vault.habana.ai/gaudi-docker/1.0.0/amzn2/habanalabs/pytorch-installer:1.0.0-532
  ```

  </details>
</details>

**OPTIONAL:** Add the following flag to mount a local host share folder to the docker in order to be able to transfer files out of docker:

```
-v $HOME/shared:/root/shared
```
<br />

<center>

Setup complete, please proceed to [Run Reference Models](#Run-Reference-Models)

</center>

<br />

---

<br />

## Run Reference Models
Congratulations! Your system should now be setup and ready to run models!

Please refer to our Model-References Github pages for model refernces and how to run them.   
Tensorflow:  
[Model References Tensorflow](https://github.com/HabanaAI/Model-References/tree/master/TensorFlow)  
For Pytorch:  
[Model References Pytorch](https://github.com/HabanaAI/Model-References/tree/master/PyTorch)

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
[GAUDI_Qualification_Library](https://docs.habana.ai/en/latest/Qualification_Library/GAUDI_Qualification_Library.html)

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
[Installation Guide](https://docs.habana.ai/en/latest/Installation_Guide/GAUDI_Installation_Guide.html)

For any additional debugging assistance, please refer to the following link:  
[Debugging Guide](https://docs.habana.ai/en/latest/Debugging_Guide/Debugging_Guide.html)

<br />

---

<br />

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
