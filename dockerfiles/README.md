# Gaudi Dockers

By installing, copying, accessing, or using the software, you agree to be legally bound by the terms and conditions of the Habana software license agreement [defined here](https://habana.ai/habana-outbound-software-license-agreement/).

## Table of Contents
  - [Overview](#overview)
  - [docker_build](#docker_build)


<br />

---

<br />

## Overview

Welcome to Gaudi Dockers!

This folder contains some Gaudi dockerfiles and docker_build.sh that can be used as reference to build docker images for Gaudi.

<br />

---

<br />

## docker_build

This script can be used as reference to build docker images for Gaudi.

### How to Build Docker Images from Habana Dockerfiles

1. Download Docker files and build script from Github to local directory

2. Run build script to generate Docker image
    ```
    ./docker_build.sh mode [tensorflow,pytorch] os [ubuntu18.04,ubuntu20.04,amzn2,centos8.3,rhel8.3] tf_version [2.9.1, 2.8.2]
    ```
    For example:
    ```
    ./docker_build.sh tensorflow ubuntu20.04 2.9.1
    ```