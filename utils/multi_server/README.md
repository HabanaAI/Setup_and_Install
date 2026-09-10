## Enabling SSH Communication Between Docker Containers in a Cluster

This guide outlines a method to enable multiple Docker containers in a cluster to communicate with each other using SSH. 
This setup is a prerequisite for running a training workload on multiple servers together, which helps reduce overall training times. 
Following these steps will allow you to quickly set up containers in a semi-automated way with minimal effort.

### Prerequisites

* A common folder accessible by all containers.
* An empty file named `nodes.txt` within the common folder.

### Steps

1. **Prepare the Shared Folder (IMPORTANT):**
   - Create a shared folder accessible by all Docker containers in the cluster.
   - Inside this folder, create an empty file named `nodes.txt`.

   **Example:**

   ```
   /root/common/nodes.txt
   ```

2. **Populate `nodes.txt` with all the containers' IP addresses:**
   - To obtain a container's IP address, run the following command inside the container:

     ```bash
     ip route get 1 | awk '{print $7}'
     ```

   - Edit the `nodes.txt` file and add the IP address of each container you intend to use in the cluster, one per line.

   **Example `nodes.txt` content:**

   ```
   172.17.0.1
   172.17.0.2
   172.17.0.3
   ```



3. **Collect SSH Keys (Run Once per container):**
   - In **each** Docker container, execute the following command to collect SSH keys:

     ```bash
     bash collect_ssh_keys.sh
     ```

4. **Distribute SSH Keys (Run Once per container):**
   - Proceed with this step only after having completed STEP 3 on **each** container.
   - In **each** Docker container, execute the following command to distribute SSH keys:

     ```bash
     bash distribute_ssh_keys.sh
     ```

5. **Verify SSH Communication:**
   - After running the previous steps, the containers should be able to communicate with each other using SSH.
   - Use the `lsof -i` command to verify if the selected SSH port (usually 4022) is listening:

     ```bash
     lsof -i
     ```

   A successful output will look similar to this:

     ```
     COMMAND PID USER   FD  TYPE DEVICE SIZE/OFF NODE NAME
     sshd    74 root    3u  IPv4 66262911     0t0  TCP *:4022 (LISTEN)
     sshd    74 root    4u  IPv6 66262913     0t0  TCP *:4022 (LISTEN)
     ```

   - If the port is not listening, try changing the `PORT_ID` variable in both `collect_ssh_keys.sh` and `distribute_ssh_keys.sh` to a different port (e.g., 5022) and repeat STEPS 3 and 4.

6. **Run Multi-Server Training:**
   - Refer to the following guide for instructions on running multi-server training commands on each worker node:

     ```
     https://github.com/HabanaAI/Model-References/blob/master/PyTorch/generative_models/stable-diffusion/README.md#multi-server-training-examples
     ```
