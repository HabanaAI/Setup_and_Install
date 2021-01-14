### Gaudi Setup and Installation - DRAFT, INTERNAL ONLY
Setup and Installation Instructions for Docker images, Docker image creation, and Habana(TM) packages on bare metal.

GitHub version of the internal Installation guide; Instructions on how to install Habana binaries on bare metal, or create docker images.  Will cover three scenarios:
* Install DKMS (PCIe) driver
* Installation of Habana Gaudi Drivers leveraging the Public Vault
* Dockerfile for full Synapse AI with TensorFlow or PyTorch with institutions with access to the Public Vault.  Will show how to build your own Docker image.
* Management of additional scripts

### Setting Up and Installing Using Docker Images
## Install base drivers
1. Remove old packages habanalabs-dkms
```
sudo dpkg -P habanalabs-dkms
```
2. Download and install habanalabs-dkms --  **TODO: This is an internal link, does not work, would need external Artifacotry** 
```
sudo wget https://artifactory.habana-labs.com/repo-ubuntu18.04/pool/qa/h/habanalabs/habanalabs-dkms_0.12.0-353_all.deb
sudo dpkg -i habanalabs-dkms_0.12.0-353_all.deb
```
3. Unload the driver if loaded
```
sudo rmmod habanalabs
```
4. Update firmware. Be careful when updating firmware - it cannot be interrupted. Otherwise, the system may become non-functional.
```
sudo hl-fw-loader --yes
```
5. Load the driver
```
sudo modprobe habanalabs
```
## Install the Docker image
1. Stop running dockers
```
docker stop $(docker ps -a -q)
```

2. Download docker ---   **Note THIS IS an INTERNAL repo, this will be converted to Docker Hub for final usage**
```
docker pull artifactory.habana-labs.com/docker-local/0.12.0/ubuntu18.04/habanalabs/tensorflow-installer:0.12.0-353
```

## Launch the image
1. Run docker ---  Note: this will Need the external Artifacotry for this to work.  
**NOTE:** This assumes Imagenet dataset is under /opt/datasets/imagenet on the host. Modify accordingly.  
```
docker run -td --device=/dev/hl_controlD0:/dev/hl_controlD0 --device=/dev/hl_controlD1:/dev/hl_controlD1 --device=/dev/hl_controlD2:/dev/hl_controlD2 --device=/dev/hl_controlD3:/dev/hl_controlD3 --device=/dev/hl_controlD4:/dev/hl_controlD4 --device=/dev/hl_controlD5:/dev/hl_controlD5 --device=/dev/hl_controlD6:/dev/hl_controlD6 --device=/dev/hl_controlD7:/dev/hl_controlD7 --device=/dev/hl0:/dev/hl0 --device=/dev/hl1:/dev/hl1 --device=/dev/hl2:/dev/hl2 --device=/dev/hl3:/dev/hl3 --device=/dev/hl4:/dev/hl4 --device=/dev/hl5:/dev/hl5 --device=/dev/hl6:/dev/hl6 --device=/dev/hl7:/dev/hl7 -e DISPLAY=$DISPLAY -e LOG_LEVEL_ALL=6 -v /sys/kernel/debug:/sys/kernel/debug -v /tmp/.X11-unix:/tmp/.X11-unix:ro -v /tmp:/tmp -v /opt/datasets/imagenet:/root/tensorflow_datasets/imagenet --net=host --ulimit memlock=-1:-1 artifactory.habana-labs.com/docker-local/0.12.0/ubuntu18.04/habanalabs/tensorflow-installer:0.12.0-353
```
OPTIONAL with mounted shared folder to transfer files out of docker:
```
docker run -td --device=/dev/hl_controlD0:/dev/hl_controlD0 --device=/dev/hl_controlD1:/dev/hl_controlD1 --device=/dev/hl_controlD2:/dev/hl_controlD2 --device=/dev/hl_controlD3:/dev/hl_controlD3 --device=/dev/hl_controlD4:/dev/hl_controlD4 --device=/dev/hl_controlD5:/dev/hl_controlD5 --device=/dev/hl_controlD6:/dev/hl_controlD6 --device=/dev/hl_controlD7:/dev/hl_controlD7 --device=/dev/hl0:/dev/hl0 --device=/dev/hl1:/dev/hl1 --device=/dev/hl2:/dev/hl2 --device=/dev/hl3:/dev/hl3 --device=/dev/hl4:/dev/hl4 --device=/dev/hl5:/dev/hl5 --device=/dev/hl6:/dev/hl6 --device=/dev/hl7:/dev/hl7 -e DISPLAY=$DISPLAY -e LOG_LEVEL_ALL=6 -v /sys/kernel/debug:/sys/kernel/debug -v /tmp/.X11-unix:/tmp/.X11-unix:ro -v /tmp:/tmp -v ~/shared:/root/shared -v /opt/dataset/imagenet:/root/tensorflow_datasets/imagenet --net=host --ulimit memlock=-1:-1 artifactory.habana-labs.com/docker-local/0.12.0/ubuntu18.04/habanalabs/tensorflow-installer:0.12.0-353
```

2. Check name of your docker
```
docker ps
```

3. Run bash in your docker
```
docker exec -ti <NAME> bash 
```
## notes:  need to think about this for RPM and Debian, as well as TF and PyT instructions

### How to Build Docker Images from Habana Dockerfiles
* Dockerfile for full Synapse AI with TensorFlow or PyTorch with institutions with access to the Public Vault.  Will show how to build your own Docker image
* We will put the dockerfile itself in the repo

### Bare Metal Installation
* Installation of Habana Drivers leveraging the Public Vault – Copy from the Install guide.
* Install DKMS (PCIe) driver (and the other things that are missing when you use the TF/PyT docker image)
* How do you get to TensorFlow or PyTorch from here? 
* Next steps.. for the HW specific installation instrcutionrs (Firmware, BMC, etc).. goto our documentation (ReadtheDocs)

### How to use the Habana Container Runtime

### Managing additional scripts and add-ons
