# Gaudi Utils

By installing, copying, accessing, or using the software, you agree to be legally bound by the terms and conditions of the Intel Gaudi software license agreement [defined here](https://habana.ai/habana-outbound-software-license-agreement/).

## Table of Contents

- [Gaudi Utils](#gaudi-utils)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [manage\_network\_ifs](#manage_network_ifs)
  - [Operations](#operations)
    - [Up](#up)
    - [Down](#down)
    - [Status](#status)
    - [Set IP](#set-ip)
    - [Unset IP](#unset-ip)
  - [check\_framework\_env](#check_framework_env)
  - [Intel Gaudi Health Screen (IGHS)](#intel-gaudi-health-screen-ighs)

## Overview

Welcome to Intel Gaudi's Util Scripts!

This folder contains some Intel Gaudi utility scripts that users can access as reference.

## manage_network_ifs

Moved to habanalabs-qual Example: (/opt/habanalabs/qual/gaudi2/bin/manage_network_ifs.sh).

This script can be used as reference to bring up, take down, set IPs, unset IPs and check for status of the Intel Gaudi network interfaces.

The following is the usage of the script:

```
usage: ./manage_network_ifs.sh [options]

options:
       --up         toggle up all Intel Gaudi network interfaces
       --down       toggle down all Intel Gaudi network interfaces
       --status     print status of all Intel Gaudi network interfaces
       --set-ip     set IP for all internal Intel Gaudi network interfaces
       --unset-ip   unset IP from all internal Intel Gaudi network interfaces
  -v,  --verbose    print more logs
  -h,  --help       print this help

Note: Please run this script with one operation at a time
```
## Operations

Before executing any operation, this script finds all the Intel Gaudi network interfaces available on the system and stores the Intel Gaudi interface information into a list.
The list will be used for the operations. If no Intel Gaudi network interface is found, the script will exit.

### Up

Use the following command to bring all Intel Gaudi network interfaces online:
```
sudo manage_network_ifs.sh --up
```
Once all the Intel Gaudi interfaces are toggled up, IPs will be set by default. Please refer [Set Ip](#set-ip) for more detail. To unset IPs, run this script with '--unset-ip'
### Down

Use the following command to bring all Intel Gaudi network interfaces offline:
```
sudo manage_network_ifs.sh --down
```
### Status

Print the current operational state of all Intel Gaudi network interfaces such as how many ports are up/down:
```
sudo manage_network_ifs.sh --status
```
### Set IP

Use the following command to assign a default IP for all Intel Gaudi network interfaces:
```
sudo manage_network_ifs.sh --set-ip
```
Note: Default IPs are 192.168.100.1, 192.168.100.2, 192.168.100.3 and so on
### Unset IP

Remove IP from all available Intel Gaudi network interfaces by the following command:
```
sudo manage_network_ifs.sh --unset-ip
```

## check_framework_env

This script can be used as reference to check the environment for running PyTorch on Intel Gaudi.

The following is the usage of the script:

```
usage: check_framework_env.py [-h] [--cards CARDS]

Check health of Intel Gaudi for PyTorch

optional arguments:
  -h, --help            show this help message and exit
  --cards CARDS         Set number of cards to test (default: 1)
```

## Intel Gaudi Health Screen (IGHS)

**Intel Gaudi Health Screen** (IGHS) tool has been developed to verify the cluster network health through a suite of diagnostic tests. The test
includes checking gaudi port status, running small workloads, and running standard collective operations arcoss multiple systems.

``` bash
usage: screen.py [-h] [--initialize] [--screen] [--target-nodes TARGET_NODES]
                 [--job-id JOB_ID] [--round ROUND] [--config CONFIG]
                 [--ighs-check [{node,hccl-demo,none}]] [--node-write-report]
                 [--node-name NODE_NAME] [--logs-dir LOGS_DIR]

optional arguments:
  -h, --help            show this help message and exit
  --initialize          Downloads Necessary Repos and Creates Report Template
  --screen              Starts Health Screen for Cluster
  --target-nodes TARGET_NODES
                        List of target nodes
  --job-id JOB_ID       Needed to identify hccl-demo running log
  --round ROUND         Needed to identify hccl-demo running round log
  --config CONFIG       Configuration file for Health Screener
  --ighs-check [{node,hccl-demo,none}]
                        Check IGHS Status for Node (Ports status, Device Acquire Fail, Device Temperature) or all_reduce
                        (HCCL_DEMO between paris of nodes)
  --node-write-report   Write Individual Node Health Report
  --node-name NODE_NAME Name of Node
  --logs-dir LOGS_DIR   Output directory of health screen results
```

To run a full IGHS test, run the below command:

``` bash
# Creates IGHS Report and screens clusters for any infected nodes.
# Will check Level 1 and 2 by default
python screen.py --initialize --screen
```