# Gaudi Installation Reference Scripts

By installing, copying, accessing, or using the software, you agree to be legally bound by the terms and conditions of the Habana software license agreement [defined here](https://habana.ai/habana-outbound-software-license-agreement/).

## Table of Contents

  - [Overview](#overview)
  - [System Setup](#System-Setup)
  - [TensorFlow Setup](#TensorFlow-Setup)
  - [PyTorch Setup](#PyTorch-Setup)


<br />

---

<br />

## Overview

Welcome to Gaudi's Installation Reference Scripts!

This folder contains some Gaudi installation scripts that users can access as reference for setting up and installing the various software components for the Gaudi platform.

For more detailed step by step information, please reference our [Habana docs](https://docs.habana.ai/en/latest/Installation_Guide/GAUDI_Installation_Guide.html).

<br />

---

<br />

## System Setup

Our provided setupinstall.sh script can be used as reference to install the supported python, install the Synapse software stack, and setup hugepages.

The following is the usage of the script:

```
Usage: sudo -E ./synapse_installation.sh [-h]
   -h ............. Optional; show help

This script installs required OS packages and Habanalabs Gaudi drivers
Requirements:
Clean, updated OS installation
User must have sudo access with no password
OS support:
 - Ubuntu 18.04
 - Ubuntu 20.04
 - CentOS 7.8 and 8.3
 - Amazon Linux 2
```

## TensorFlow Setup

Our provided tf_installation.sh script can be used as reference to install the supported TensorFlow framework including the Habana Plugins.

The following is the usage of the script:

```
Help: Setting up execution of TensorFlow for Gaudi
############################################################
The script sets up environment for recommended TensorFlow version: ${TF_RECOMMENDED_PKG}.
It auto-detects OS and installed Habana SynapseAI.
List of optional parameters:
  --tf <tf package>              - full TensorFlow package name and version to install via PIP. (default: '${TF_RECOMMENDED_PKG}')
                                   I.e. 'tensorflow-cpu==<ver>'. Alternatively, it can be path to remotely located package (as accepted by PIP).
  --ndeps                        - don't install rpm/deb dependencies
  --extra_deps                   - install extra model references' rpm/deb dependencies
  --pip_user <true/false>        - force pip install with or without --user flag. (default: --user is added if USER is not root)
```

## PyTorch Setup

Our provided pytorch_installation.sh script can be used as reference to install the supported PyTorch framework including Habana.

The following is the usage of the script:

```
Help :Setting up execution of Pytorch for Gaudi
############################################################
  -v <software version>           - Habana software version eg 1.3.0
  -b <build/revision>             - Habana build number eg: 499 in 1.3.0-499
  -os <os version>                - OS version <ubuntu2004/ubuntu1804/amzn2/rhel79/rhel83/centos83>
  -ndep                           - dont install rpm/deb dependecies
  -sys                            - eg: install python packages without --user
  -u                              - eg: install python packages with --user
```