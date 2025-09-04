# Gaudi Docker Images Builder

## Table of Contents
  - [Overview](#overview)
  - [Support matrix](#support-matrix)
  - [Build docker](#build-docker)

<br />

---

<br />

## Overview

This folder contains Gaudi dockerfiles and makefiles that can be used to build Habanalabs docker images for Gaudi.

<br />

---

<br />

## Support Matrix

| BUILD_OS       | Internal torch | Upstream torch | Custom python |
|----------------|:--------------:|:--------------:|:-------------:|
| ubuntu22.04    |       Yes      |       Yes      |      3.11     |
| ubuntu24.04    |       Yes      |                |               |
| rhel9.4        |       Yes      |       Yes      |      3.12     |
| rhel9.6        |       Yes      |                |               |
| tencentos3.1   |       Yes      |                |               |
| opencloudos9.2 |       Yes      |                |               |
| navix9.4       |       Yes      |                |               |

<br/>
You can also build triton-installer, which is based on ubuntu22.04 OS

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
    #### Build pytorch image for rhel9.4:
    ```
    cd pytorch
    make build BUILD_OS=rhel9.4
    ```

    #### Build pytorch image for rhel9.4 with python3.12:
    ```
    cd pytorch
    make build BUILD_OS=rhel9.4 PYTHON_CUSTOM_VERSION=3.12
    ```

    #### Build pytorch image for ubuntu22.04 with upstream pytorch:
    ```
    cd pytorch
    make build BUILD_OS=ubuntu22.04 TORCH_TYPE=upstream
    ```

    #### Build triton image (default OS - ubuntu22.04):
    ```
    cd triton
    make build
    ```

    #### Build triton vllm backend (default OS - ubuntu22.04):
    ```
    cd triton_vllm_backend
    make build BUILD_OS=ubuntu22.04
    ```

3. Build command variables

    #### Optional Parameters
    * BUILD_OS - set the OS to build (default ubuntu22.04)
    * PYTHON_CUSTOM_VERSION - build OS with different python version than default - available ubuntu22.04 with python3.11 and rhel9.4 with python3.12
    * TORCH_TYPE - build pytorch docker with upstream or fork (internal) torch version (default fork)
    * BUILD_DIR - the folder where the build be executed from (default dockerbuild in image folder)
    * VERBOSE - set to TRUE to echo the commands (default FALSE)
    * DOCKER_CACHE - set to TRUE to use cache for building docker image (default FALSE)

4. Instructions for triton-vllm-back-end server

   * Run the backend container as described in [habana docs](https://docs.habana.ai/en/latest/PyTorch/Inference_on_PyTorch/Triton_Inference.html?highlight=triton%20inference#run-the-backend-container)
   * Start the triton server
     ```bash
     tritonserver --model-repository samples/model_repository
     ```
     The current samples/model_repository/vllm_model contains llama27B 1x.We also have sample model files for llama2 7b/70b and qwen2-7b respectively under samples/model_repository/test_models folder. To use them , copy the model.json and config.pbtxt to vllm_model folder structure.
   * To test with client, please follow the instructions [here](https://github.com/triton-inference-server/vllm_backend?tab=readme-ov-file#sending-your-first-inference)

