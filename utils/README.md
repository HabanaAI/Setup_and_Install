# Gaudi Utils

By installing, copying, accessing, or using the software, you agree to be legally bound by the terms and conditions of the Habana software license agreement [defined here](https://habana.ai/habana-outbound-software-license-agreement/).

## Table of Contents

  - [Overview](#overview)
  - [manage_network_ifs.sh](#manage_network_ifs)


<br />

---

<br />

## Overview

Welcome to Gaudi's Util Scripts!

This folder contains some Gaudi utility scripts that users can access as reference.

<br />

---

<br />

## manage_network_ifs

This script can be used as reference to bring up, take down, set IPs, unset IPs and check for status of the Gaudi network interfaces.

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
## Operations

Before executing any operation, this script finds all the Habana network interfaces available on the system and stores the Habana interface information into a list.  
The list will be used for the operations. If no Habana network interface is found, the script will exit. 

### Up

Use the following command to bring all Habana network interfaces online:
```
sudo manage_network_ifs.sh --up
```
Once all the Habana interfaces are toggled up, IPs will be set by default. Please refer [Set Ip](#set-ip) for more detail. To unset IPs, run this script with '--unset-ip'
### Down

Use the following command to bring all Habana network interfaces offline:
```
sudo manage_network_ifs.sh --down
```
### Status

Print the current operational state of all Habana network interfaces such as how many ports are up/down:
```
sudo manage_network_ifs.sh --status
```
### Set IP

Use the following command to assign a default IP for all Habana network interfaces:
```
sudo manage_network_ifs.sh --set-ip
```
Note: Default IPs are 192.168.100.1, 192.168.100.2, 192.168.100.3 and so on
### Unset IP

Remove IP from all available Habana network interfaces by the following command:
```
sudo manage_network_ifs.sh --unset-ip
```
