# Gaudi Docker Images Builder

## Table of Contents
  - [Overview](#overview)
  - [Build docker](#docker_build)


<br />

---

<br />

## Overview

This folder contains Gaudi dockerfiles and makefiles that can be used to build Habanalabs docker images for Gaudi.

<br />

---

<br />

## Build Docker

This script can be used as reference to build docker images for Gaudi.

### How to Build Docker Images from Habana Dockerfiles

1. Go into the folder of the image type you would like to build:
    * base
    * pytorch
    * triton

2. Run build command to generate Docker image
    ```
    make build
    ```
    Examples:
    #### Build pytorch image for rhel9.2:
    ```
    cd pytorch
    make build BUILD_OS=rhel9.2
    ```

    #### Build triton image (default OS - ubuntu22.04):
    ```
    cd triton
    make build
    ```

3. Build command variables

    #### Optional Parameters
    * BUILD_OS - set the OS to build (default ubuntu22.04)
    * BUILD_DIR - the folder where the build be executed from (default dockerbuild in image folder)
    * VERBOSE - set to TRUE to echo the commands (default FALSE)
    * DOCKER_CACHE - set to TRUE to use cache for building docker image (default FALSE)