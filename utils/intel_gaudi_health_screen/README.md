# Intel Gaudi Health Screen 2.1.1

A large scale Intel Gaudi cluster contains a lot of moving parts. To ensure distributed training proceeds smoothly, it is recommended to check the
cluster network health. Troubleshooting issues on a large cluster can be a tedious act. To simplify the debugging process the
**Intel Gaudi Health Screen** (IGHS) tool has been developed to verify the cluster network health through a suite of diagnostic tests. The test
includes checking gaudi port status, running small workloads, and running standard collective operations arcoss multiple systems

IGHS is capable of running on a Kubernetes cluster or on a baremetal cluster. It is an active scan, which will block other users from training
on a gaudi systems until the scans are complete. At the end of the scans, IGHS produces a CSV report detailing the state of each gaudi card.

It is reccomended to run IGHS in the below scenarios:

* After a system upgrade/update
* Before running a long term training
* Pinpointing problematic systems in a cluster if a problem can't be isolated to a single system

IGHS runs a multi-tiered configurable scan:

* Level 1 - Individual System Diagnostics
* Level 2 - Multi-System Communication Diagnostics

## Level 1 - Individual System Diagnostic

Level 1 focuses on individual Gaudi Cards Health Diagnostics.

| Test                      | Description                                                |
| ------------------------- | ---------------------------------------------------------- |
| Gaudi Ports Status        | Checks if ports are DOWN                                   |
| Device Acquire Failures   | Checks if devices are busy                                 |
| Device Temperatue         | Checks if devices temperatures are in acceptable range     |

**2 System Cluster Example**

Here is an example of running IGHS on a 2 system cluster. It identifies the Gaudi Cards that have down links, device acquire issues, and
flags for multi node communication failure

| node_id  | index | module_id | pci_address  | temperature_C | temperature_C | device_acquire_fail | down_links | multi_node_fail | missing |
| -------- | ----- | --------- | ------------ | ------------- | ------------- | ------------------- | ---------- | ----------------| ------- |
| sys-9-05 | 0     | 3         | 0000:19:00.0 | 22            |               | False               | [9]        | True            | False   |
| sys-9-05 | 1     | 7         | 0000:b3:00.0 | 60            | WARN          | False               | [7]        | True            | False   |
| sys-9-05 | 2     | 2         | 0000:1a:00.0 | 84            | CRITICAL      | False               | [5, 7]     | True            | False   |
| sys-9-05 | 3     | 6         | 0000:b4:00.0 | 23            |               | False               | [4]        | True            | False   |
| sys-9-05 | 4     | 1         | 0000:33:00.0 | 25            |               | False               | [4, 5]     | True            | False   |
| sys-9-05 | 5     | 5         | 0000:cc:00.0 | 24            |               | False               | [4, 5]     | True            | False   |
| sys-9-05 | 6     | 0         | 0000:34:00.0 | 27            |               | False               | [4, 5]     | True            | False   |
| sys-4-04 | 7     | 4         | 0000:cd:00.0 | 28            |               | False               | []         | False           | False   |
| sys-4-04 | 0     | 3         | 0000:19:00.0 | 28            |               | False               | []         | False           | False   |
| sys-4-04 | 1     | 7         | 0000:b3:00.0 | 28            |               | False               | []         | False           | False   |
| sys-4-04 | 2     | 2         | 0000:1a:00.0 | 28            |               | False               | []         | False           | False   |
| sys-4-04 | 3     | 0         | 0000:34:00.0 | 24            |               | False               | []         | False           | False   |
| sys-4-04 | 4     | 6         | 0000:b4:00.0 | 24            |               | False               | []         | False           | False   |
| sys-4-04 | 5     | 1         | 0000:33:00.0 | 21            |               | False               | []         | False           | False   |
| sys-4-04 | 6     | 5         | 0000:cc:00.0 | 21            |               | False               | []         | False           | False   |
| sys-4-04 | 7     | 4         | 0000:cd:00.0 | 26            |               | False               | []         | False           | False   |

``` log
[2023-02-07 09:02:39] INFO Infected (Temperature WARN) 1 Node: ['sys-9-05']
[2023-02-07 09:02:39] INFO Infected (Temperature CRITICAL) 1 Node: ['sys-9-05']
[2023-02-07 09:02:39] INFO Infected 1 Node: ['sys-9-05']
[2023-02-07 09:02:39] INFO Missing 0 Node: []
[2023-02-07 09:02:39] INFO Healthy 1 Node: ["sys-4-04"]

[2023-02-07 09:02:39] INFO Detected 2 Node: ["sys-4-04","sys-9-05"]

```


## Level 2 - Multi-System Communication Diagnostics

Level 2 performs a collective communication all reduce test between multiple system through [HCCL_DEMO](https://github.com/HabanaAI/hccl_demo] repo.
It runs X rounds with unique pairs of systems ensuring that a system is able to communicate across different sets of systems. If no
pair systems have failed, then the testing will stop. If there was a system with communication issues, it will be flagged on the
first round.

** Multi Node Cluster Example**

Here is an example of running IGHS for 2 rounds and the results gets recorded to `hccl_demo_health_report.csv`. It identifies node pairs that failed the all_reduce test. If "True" is flagged
in the multi_node_fail column, then one of the nodes has a communication issue. List of infected nodes will be printed out to
the log as well as the `health_report.csv` multi_node_fail column.

| round | group_id | node_ids                 | num_nodes | multi_node_fail | missing | qpc_fail |
| ----- | -------- | ------------------------ | --------- | --------------- | ------- | -------- |
| 0     | 11       | ['sys-7-01', 'sys-9-05'] | 2         | True            | False   | True     |
| 0     | 4        | ['sys-2-03', 'sys-4-04'] | 2         | True            | True    | False    |
| 0     | 13       | ['sys-6-06', 'sys-9-06'] | 2         | False           | False   | False    |
| 0     | 1        | ['sys-3-01', 'sys-9-01'] | 2         | False           | False   | False    |
| 0     | 2        | ['sys-6-03', 'sys-8-01'] | 2         | False           | False   | False    |
| 0     | 0        | ['sys-3-06', 'sys-6-02'] | 2         | False           | False   | False    |
| 0     | 10       | ['sys-2-01', 'sys-4-01'] | 2         | False           | False   | False    |
| 0     | 6        | ['sys-6-05', 'sys-9-03'] | 2         | False           | False   | False    |
| 0     | 14       | ['sys-4-05', 'sys-8-03'] | 2         | False           | False   | False    |
| 0     | 12       | ['sys-6-04', 'sys-8-05'] | 2         | False           | False   | False    |
| 0     | 8        | ['sys-7-06', 'sys-9-02'] | 2         | False           | False   | False    |
| 0     | 5        | ['sys-3-04', 'sys-7-02'] | 2         | False           | False   | False    |
| 0     | 3        | ['sys-4-03', 'sys-6-01'] | 2         | False           | False   | False    |
| 0     | 7        | ['sys-2-06', 'sys-3-03'] | 2         | False           | False   | False    |
| 0     | 9        | ['sys-2-04', 'sys-9-04'] | 2         | False           | False   | False    |
| 1     | 1        | ['sys-3-04', 'sys-4-05'] | 2         | False           | False   | False    |
| 1     | 20       | ['sys-2-03', 'sys-7-02'] | 2         | True            | True    | False    |
| 1     | 19       | ['sys-3-01', 'sys-9-03'] | 2         | False           | False   | False    |
| 1     | 0        | ['sys-3-03', 'sys-9-04'] | 2         | False           | False   | False    |
| 1     | 12       | ['sys-4-04', 'sys-6-02'] | 2         | False           | False   | False    |
| 1     | 9        | ['sys-4-03', 'sys-6-05'] | 2         | False           | False   | False    |
| 1     | 14       | ['sys-3-06', 'sys-6-04'] | 2         | False           | False   | False    |
| 1     | 15       | ['sys-4-01', 'sys-8-03'] | 2         | False           | False   | False    |
| 1     | 3        | ['sys-8-01', 'sys-9-05'] | 2         | True            | False   | False    |
| 1     | 8        | ['sys-6-03', 'sys-9-02'] | 2         | False           | False   | False    |
| 1     | 7        | ['sys-2-06', 'sys-6-01'] | 2         | False           | False   | False    |
| 1     | 10       | ['sys-6-06', 'sys-8-06'] | 2         | False           | False   | False    |
| 1     | 11       | ['sys-3-02', 'sys-7-04'] | 2         | False           | False   | False    |
| 1     | 17       | ['sys-8-04', 'sys-8-05'] | 2         | False           | False   | False    |
| 1     | 18       | ['sys-4-02', 'sys-9-01'] | 2         | False           | False   | False    |
| 1     | 16       | ['sys-2-02', 'sys-9-06'] | 2         | False           | False   | False    |

Logs show that we have 1 Infected Nodes and 1 Missing Node. Missing node represents a node that hasn't been tested yet and there are standard checks to see why it hasn't
been tested, such as having missing cards, it is occupied by another session, or it is a MISC use case.

``` log
[2023-02-07 09:02:39] INFO Infected 1 Node: ['sys-9-05']
[2023-02-07 09:02:39] INFO Missing 1 Node: ['sys-2-03']
[2023-02-07 09:02:39] INFO Healthy 34 Node: ["sys-2-01","sys-2-02","sys-2-03","sys-2-04","sys-2-06","sys-3-01","sys-3-02","sys-3-03","sys-3-04","sys-3-06","sys-4-01","sys-4-02","sys-4-03","sys-4-04","sys-4-05","sys-6-01","sys-6-02","sys-6-03","sys-6-04","sys-6-05","sys-6-06","sys-7-01","sys-7-02","sys-7-04","sys-7-06","sys-8-01","sys-8-03","sys-8-04","sys-8-05","sys-8-06","sys-9-01","sys-9-02","sys-9-03","sys-9-04","sys-9-06"]

[2023-02-07 09:02:39] INFO Detected 36 Node: ["sys-2-01","sys-2-02","sys-2-03","sys-2-04","sys-2-06","sys-3-01","sys-3-02","sys-3-03","sys-3-04","sys-3-06","sys-4-01","sys-4-02","sys-4-03","sys-4-04","sys-4-05","sys-6-01","sys-6-02","sys-6-03","sys-6-04","sys-6-05","sys-6-06","sys-7-01","sys-7-02","sys-7-04","sys-7-06","sys-8-01","sys-8-03","sys-8-04","sys-8-05","sys-8-06","sys-9-01","sys-9-02","sys-9-03","sys-9-04","sys-9-05","sys-9-06"]
[2023-02-07 09:02:39] INFO 1 Nodes w/ missing cards: ['sys-2-03']
```

## Setup

IGHS is compatible with python3 default packages and does not require additional packages
to be installed

If your setup envionrment requires custom configruation, update the yaml files located in the templates folder.

If running on bare metal system, then install `pdsh` to your system.

Update [config.yaml](config.yaml) to match your system envionrment

``` yaml
# Sets IGHS to screen for K8s or Bare Metal Envionrment (k8s, bare-metal).
system-info:
  type: "k8s"
  # Namespace is only required for k8s settings
  namespace: "intelgaudi"
  # Can specify specific systems. For k8s, to scan entire cluster comment out hostfile
  # hostfile: "./hostfile"

  # Bare Metal Configurations
  ssh-path: "./ssh"
  tcp-interface: "10.3.124.0/24"

# Image to run Intel Gaudi Health Screen
image: "vault.habana.ai/gaudi-docker/1.16.0/ubuntu22.04/habanalabs/pytorch-installer-2.2.2:latest"

# Node Label used to identify a Intel Gaudi Node
gaudi-node-label: "ighs_label=gaudi"

# Controls granularity of Logs (INFO, DEBUG, WARN, ERROR, CRITICAL)
log-level: "DEBUG"

# Level 1 - Checks Individual Node Health (Ports status, Device Acquire failure, Device Temperature)
level-1:
  run: true
  timeout_s: 150
  # Number of times to check Port Status
  num-checks-link-state: 10

# Level 2 - Checks All Reduce between node pairs in the cluster.
level-2:
  run: true
  timeout_s: 130
  # Number of times to check Network connections between nodes
  num-rounds: 5
```

To learn the features of IGHS, run the below command:

``` bash
python screen.py --help

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

To Run IGHS, run the below command:

``` bash
# Creates IGHS Report and screens clusters for any infected nodes.
# Will check Level 1 and 2 by default
python screen.py --initialize --screen
```

IGHS can alternatively be run through below script:

``` bash
# Creates IGHS Report and screens clusters for any infected nodes.
# Will check Level 1 and 2 by default
./run_ighs.sh
```

### Run on BareMetal

To run on bare-metal systems update the [config.yaml](config.yaml) to use bare-metal configuration.

``` yaml
# Sets IGHS to screen for K8s or Bare Metal Envionrment (k8s, bare-metal).
system-info:
  type: "bare-metal"
  # Namespace is only required for k8s settings
  namespace: "intelgaudi"
  # Can specify specific systems. For k8s, to scan entire cluster comment out hostfile
  hostfile: "./hostfile"

  # Bare Metal Configurations
  ssh-path: "./ssh"
  tcp-interface: "10.3.124.0/24"

# Image to run Intel Gaudi Health Screen
image: "vault.habana.ai/gaudi-docker/1.16.0/ubuntu22.04/habanalabs/pytorch-installer-2.2.2:latest"

# Node Label used to identify a Intel Gaudi Node
gaudi-node-label: "brightcomputing.com/node-category=gaudi"

# Controls granularity of Logs (INFO, DEBUG, WARN, ERROR, CRITICAL)
log-level: "DEBUG"

# Level 1 - Checks Individual Node Health (Ports status, Device Acquire failure, Device Temperature)
level-1:
  run: true
  timeout_s: 150
  # Number of times to check Port Status
  num-checks-link-state: 10

# Level 2 - Checks All Reduce between node pairs in the cluster.
level-2:
  run: true
  timeout_s: 130
  # Number of times to check Network connections between nodes
  num-rounds: 5
```

Before running the screening test, you need to generate the ssh key used for passwordless ssh:

``` bash
# Keys to setup initial bare-metal passwordless ssh connection between systems
ssh-keygen -t rsa -f ssh/ighs_rsa
chmod 600 ssh/ighs_rsa;
chmod 644 ssh/ighs_rsa.pub;

# Keys to setup containers passwordless ssh connection
ssh-keygen -t rsa -f template/bare-metal/ssh/id_rsa
chmod 600 template/bare-metal/ssh/id_rsa;
chmod 644 template/bare-metal/ssh/id_rsa.pub;

cat template/bare-metal/ssh/id_rsa.pub > template/bare-metal/sshauthorized_keys
```

## Recovery Steps

| Issue                     | Description                                                                             |
| ------------------------- | --------------------------------------------------------------------------------------- |
| Down Internal Links       | Need to investigate Gaudi Card Health                                                   |
| Down External Links       | Check Cable, switches, and Gaudi Card Health                                            |
| QPC Issues                | Network Configuration issue (stale gaudinet.json, stale NIC configurations, etc... )    |
| Missing Cards             | Need to investigate Gaudi Card Health                                                   |
| k8s Issues                | Node Resources are not set/configured properly                                          |
