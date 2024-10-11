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

    #### Build triton vllm backend (default OS - ubuntu22.04):
    ```
    cd triton_vllm_backend
    make build BUILD_OS=ubuntu22.04
    ```

3. Build command variables

    #### Optional Parameters
    * BUILD_OS - set the OS to build (default ubuntu22.04)
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

