# Copyright (c) 2024 Habana Labs, Ltd. an Intel Company.Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import random, math, os, yaml, glob, json

import logging
_logger = logging.getLogger("health_screener")

def find_groups(nodes_to_test, groups_tracker):
    """ Find a list of node groups to run hccl_demo all reduce test

    Args:
        nodes_to_test ([str]): Nodes list used to create a group of nodes for hccl_demo
        groups_tracker ([str]): History of used groups. A group has to be unique

    Returns:
        ([str],[str]): Unique list of groups of nodes, History of used groups
    """
    random.shuffle(nodes_to_test)

    found_unique      = True
    num_nodes         = len(nodes_to_test)
    node_groups       = list()
    max_num_groups    = num_nodes // 2
    max_combinations  = (math.factorial(num_nodes)) / (math.factorial(num_nodes-2) * 2)
    _logger.debug(f"nodes_to_test {len(nodes_to_test)}: {nodes_to_test}")

    def add_unique_group_id(interval=2):
        nonlocal node_groups, nodes_to_test
        i            = 1
        max_attempts = 10
        found_unique = False

        if len(groups_tracker) >= max_combinations:
            _logger.info(f"Reached maximum combinations {max_combinations} for {num_nodes} Nodes")
            return found_unique

        node_group, group_id = find_group_id(nodes_to_test, i, interval=interval)

        while group_id in groups_tracker:
            if i > max_attempts:
                _logger.warn(f"Max attempt {max_attempts} reached for finding unique pair combination.")
                return found_unique

            node_group, group_id = find_group_id(nodes_to_test, i, interval=interval)
            if group_id == "":
                return found_unique

            i += 1

        found_unique = True
        groups_tracker.append(group_id)
        node_groups.append(node_group)

        for n in node_group:
            nodes_to_test.remove(n)

        return found_unique


    if num_nodes == 1:
        _logger.warn(f"Need more than 1 Node to test all_reduce")
        return False

    if num_nodes % 2 != 0:
        # Ensures that every node has a group to test.
        found_unique = add_unique_group_id(interval=3)

    while len(node_groups) < max_num_groups and found_unique:
        found_unique = add_unique_group_id()

        if not found_unique:
            _logger.debug(f"Finished searching for Unique pair combinations")
            break

    return node_groups, groups_tracker

def find_group_id(nodes_to_test, start, interval=2):
    """ Finds a group of nodes and combines to form a group id

    Args:
        nodes_to_test ([str]): Viable node list
        start (int): Index of next potential node id
        interval (int, optional): The size of the group id. Most common is pairs of nodes. Defaults to 2.

    Returns:
        ([str], str): Potential nodes and their group id
    """
    group_id = ""

    if len(nodes_to_test) == 0:
        return [], group_id

    node_group = [nodes_to_test[0]]
    node_group.extend(nodes_to_test[start:start+interval-1])

    if len(node_group) > 1:
        node_group.sort()
        group_id = "".join(node_group)

    return node_group, group_id

def gather_hccl_logs(job_path, round, log_dir, health_report):
    """ Retrieve hccl_demo log files based on the job yamls executed

    Args:
        job_path (str): Base directory of job yamls executed
        round (int): Round to retrieve HCCL_Demo logs
        log_dir (str): Base directory of HCCL_Demo logs
        health_report (HealthReport): Tracks and reports health of hccl_demo
    """
    path         = f"{job_path}/**/r{round}/*.yaml"
    job_files    = glob.glob(path, recursive=True)
    hccl_results = dict()

    for f_name in job_files:
        with open(f_name, 'r', newline='') as f:
            job_data = yaml.safe_load(f)

        launcher_template = job_data["spec"]["mpiReplicaSpecs"]["Launcher"]["template"]

        job_id            = launcher_template["metadata"]["labels"]["name"]
        target_nodes      = launcher_template["spec"]["containers"][0]["env"][4]["value"]
        target_nodes      = target_nodes.split(',')

        hccl_results[f"{target_nodes}"] = hccl_demo_check(job_id=f"{log_dir}/L2/r{round}/{job_id}",
                target_nodes=target_nodes, health_report=health_report, write=False)

    multi_node_fail = set()
    qpc_fail        = set()
    missing_nodes   = set()

    for results in hccl_results.values():
        if results["multi_node_fail"]:
            multi_node_fail.add(f"{results['node_ids']}")

        if results["qpc_fail"]:
            qpc_fail.add(f"{results['node_ids']}")

        if results["missing"]:
            missing_nodes.add(f"{results['node_ids']}")

    health_report.update_hccl_demo_health_report(round=round, all_node_pairs=hccl_results, multi_node_fail=multi_node_fail, qpc_fail=qpc_fail, missing_nodes=missing_nodes)

def hccl_demo_check(job_id, health_report, target_nodes=[], hccl_log=[], write=True):
    """ Check on HCCL Demo Status. Reads the output log, if it
    has "Exiting HCCL demo with code: 1" then it is treated as a
    failure

    Args:
        job_id (str): Metadata name of the Job
        health_report (HealthReport): Tracks and reports health of hccl_demo
        target_nodes ([str], optional): Nodes that are used in hccl_demo testing
        hccl_log ([str]): Log of HCCL_DEMO run
        write (bool, optional): Writes to Report. Used to collect hccl results and update Base Health Report. Default to True

    Returns:
        dict: HCCL Demo Health Report result data.
    """
    f_name_log       = f"{job_id}.log"
    round            = os.path.basename(job_id).split("-")[2][1:]
    group_id         = os.path.basename(job_id).split("-")[3]
    hccl_demo_fail   = True
    missing          = False
    qpc_fail         = False

    if len(hccl_log) == 0:
        if not os.path.exists(f_name_log):
            _logger.error(f"{f_name_log} can't be found or has no data")
            hccl_demo_fail = True
            missing        = True
        else:
            with open(f_name_log, "r", newline='') as f:
                lines = f.readlines()
                hccl_demo_fail, qpc_fail, missing, _ = analyze_hccl_log(lines)
    else:
        hccl_demo_fail, qpc_fail, missing, target_nodes = analyze_hccl_log(hccl_log)

    target_nodes.sort()
    data = {
            "round": round,
            "group_id": group_id,
            "node_ids": target_nodes,
            "num_nodes": len(target_nodes),
            "multi_node_fail": hccl_demo_fail,
            "missing": missing,
            "qpc_fail": qpc_fail
    }

    if write:
        _logger.info("***** START of Node Report *****")
        _logger.info(json.dumps(data))
        _logger.info("***** END of Node Report *****")
        health_report.write_rows(data=[data], level=2)

    return data

def analyze_hccl_log(data):
    err_phrase       = "Exiting HCCL demo with code: 1"
    err_phrase_other = "During handling of the above exception, another exception occurred:"
    err_phrase_ssh   = "ssh: Could not resolve hostname"
    err_phrase_qpc   = "Source: QPC, error"
    pass_phrase      = "Bandwidth"
    
    target_phrase    = "Target Nodes: " 

    hccl_demo_fail   = True
    missing          = False
    qpc_fail         = False
    target_nodes     = []

    for l in data:
        if l.find(err_phrase_ssh) != -1:
            hccl_demo_fail = True
            missing        = True
        elif l.find(err_phrase_qpc) != -1:
            hccl_demo_fail = True
            qpc_fail       = True
        elif l.find(err_phrase) != -1 or l.find(err_phrase_other) != -1:
            hccl_demo_fail = True
        elif l.find(pass_phrase) != -1:
            hccl_demo_fail = False
        elif l.find(target_phrase) != -1:
            colon_index = l.index(":")
            target_nodes = l[colon_index+2:].split(",")

    return hccl_demo_fail, qpc_fail, missing, target_nodes
