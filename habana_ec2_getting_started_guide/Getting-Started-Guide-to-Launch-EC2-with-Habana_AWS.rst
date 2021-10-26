
***********************************************
Getting Started Guide Launch EC2 with Habana
***********************************************

Summary
=======

This document provides guides and instructions for how to set up a
Habana Deep Learning AMI on Amazon EC2 services, and provides release
notes for the Habana image

Habana makes available on the Amazon Web Services (AWS) platform three
different VMIs, known within the AWS ecosystem as an Amazon Machine
Image (AMI). These are Deep Learning optimized AMIs for AWS instances
with Habana Training Gaudi Cards. These Images contain Habana Drivers,
Habana Firmware, and Docker.

-  Base Habana Deep Learning AMI for Ubuntu 18.04

-  Base Habana Deep Learning AMI for Ubuntu 20.04

-  Base Habana Deep Learning AMI for Amazon Linux 2

For those familiar with the AWS platform, the process of launching the
instance is as simple as logging in, selecting the Habana AMI of choice,
configuring settings as needed, then launching the VM. After launching
the VM, you can SSH into it and start building a host of AI applications
in deep learning, machine learning and data science by leveraging the
Gaudi Hardware to achieve optimal accelerated training and development.

Prerequisites
=============

These instructions assume the following:

-  You have an AWS account - https://aws.amazon.com

Getting Started
===============

Perform these preliminary setup task before creating a EC2 Instance.
This ensures a level of network security to prevent unwanted intruders.

1. Create a Virtual Private Cloud (`Get started with Amazon
   VPC <https://docs.aws.amazon.com/vpc/latest/userguide/vpc-getting-started.html>`__)

   a. Follow only `Step 1: Creating the
      VPC <https://docs.aws.amazon.com/vpc/latest/userguide/vpc-getting-started.html#getting-started-create-vpc>`__

2. Create a Security Group for VPC `(Create a Security
   Group) <https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/working-with-security-groups.html#creating-security-group>`__

   a. Follow `Authorize inbound traffic for your Linux
      instances <https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/authorizing-access-to-an-instance.html>`__
      to get access to the EC2 Instance

Create an EC2 Instance 
======================

Follow this guide `Get Started with Amazon EC2
Linux <https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EC2_GetStarted.html>`__
to learn how to create an EC2 Instance. Once ready, choose the Habana
Base AMI in order to create a Deep Learning EC2 Instance.

Pull Habana Docker Images
=========================

Follow the guide located at
https://github.com/HabanaAI/Setup_and_Install/tree/r1.1.0#pull-and-run-commands to
pull and run the Habana Docker Images for Tensorflow and Pytorch.

Release Notes for Habana Amazon Machine Images on AWS
=====================================================

Habana Deep Learning Base AMI provides a foundational platform for deep learning on Amazon EC2 instances with Habana® Gaudi® and Docker. 
The Habana Gaudi processor is designed to maximize training throughput and efficiency, while providing developers with optimized software and tools that scale to many workloads and systems.

This AMI is suitable for deploying your own custom deep learning environment at scale.

The Habana Deep Learning Base AMI is provided at no additional charge to Amazon EC2 users.

Below are the core components of Habana Deep Learning Base AMI:
	• Habana SynapseAI®
	• Containerization platforms including Docker and habanalabs-container-runtime to run Gaudi accelerated Docker containers.

For an in depth guide of getting started with Gaudi follow the guides
located at
https://developer.habana.ai/resources/getting-started-with-gaudi/

Versioning
----------

Here is the Release Notes of the Gaudi Architecture and software

https://docs.habana.ai/en/v1.1.0/Release_Notes/GAUDI_Release_Notes.html

Image Name
~~~~~~~~~~

Available Operating Systems

-  Base AMI:

   -  Habana Base AMI Ubuntu 18.04

   -  Habana Base AMI Ubuntu 20.04

   -  Habana Base AMI Amazon Linux 2

Habana Base Deep Learning AMI Packages
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Packages installed in the Habana Base AMI.

-  habanalabs-dkms 

-  habanalabs-firmware 

-  habanalabs-firmware-tools 

-  habanalabs-container-runtime 

-  habanalabs-thunk 

-  habanalabs-graph 

-  Docker 


Notices and Disclaimers
=========================

.. figure:: Intel_logo.png
   :width: 200 px
   :align: left

FTC Optimization Notice

Intel technologies may require enabled hardware, software or service
activation. No product or component can be absolutely secure.

Your costs and results may vary.

**© 2020 Intel Corporation. Intel, the Intel logo, and other Intel marks are trademarks of Intel Corporation or its subsidiaries. Other names and brands may be claimed as the property of others.**

