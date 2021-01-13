# Gaudi Setup and Installation - DRAFT, INTERNAL ONLY
Setup and Installation Instructions for Habana(TM) binaries, docker image creation

GitHub version of the internal Installation guide; Instructions on how to install Habana binaries on bare metal, or create docker images.  Will cover three scenarios:
* Install DKMS (PCIe) driver
* Installation of Habana Gaudi Drivers leveraging the Public Vault
* Dockerfile for full Synapse AI with TensorFlow or PyTorch with institutions with access to the Public Vault.  Will show how to build your own Docker image.
* Management of additional scripts


## HOW TO BUILD DOCKER IMAGES
* Dockerfile for full Synapse AI with TensorFlow or PyTorch with institutions with access to the Public Vault.  Will show how to build your own Docker image
* We will put the dockerfile itself in the repo

## Building with Habana's TensorFlow Docker Image
* Install the base drivers and then. 
*	Install the Docker image
* Launch the image
* notes:  need to think about this for RPM and Debian, as well as TF and PyT instructions

## Bare Metal Installation
* Installation of Habana Drivers leveraging the Public Vault – Copy from the Install guide.
* Install DKMS (PCIe) driver (and the other things that are missing when you use the TF/PyT docker image)
* How do you get to TensorFlow or PyTorch from here? 
* Next steps.. for the HW specific installation instrcutionrs (Firmware, BMC, etc).. goto our documentation (ReadtheDocs)

## How to use the Habana Container Runtime

## Managing additional scripts and add-ons
