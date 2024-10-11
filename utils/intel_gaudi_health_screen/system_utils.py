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

import time, os, shutil, yaml, glob, json, re
import multiprocessing
import logging

from utilities import run_cmd, copy_files
from hccl_demo_helper import find_groups, hccl_demo_check


_logger = logging.getLogger("health_screener")


class SystemUtils():

    def __init__(self, image, log_dir, remote_path="/tmp/ighs"):
        self.job_path    = "tmp/jobs"
        self.image       = image
        self.log_dir     = log_dir
        self.remote_path = remote_path

    def clear_jobs(self):
        if not os.path.exists(self.job_path):
            os.makedirs(self.job_path)

        _logger.info(f"Clearing out {self.job_path}")
        for f in os.listdir(self.job_path):
            full_path = os.path.join(self.job_path, f)
            if os.path.isdir(full_path):
                shutil.rmtree(full_path)
            else:
                os.remove(full_path)

    def extract_host(self, hostfile):
        hosts = list()
        with open(hostfile, "r") as f:
            hosts = [l.strip() for l in f]

        return hosts


class KubeUtils(SystemUtils):

    def __init__(self, image, hostfile, namespace, log_dir):
        super().__init__(image, log_dir)
        self.namespace = namespace
        self.hostfile = hostfile

    def initialize_system(self):
        self.clear_ighs_pods()
        self.clear_ighs_pods(job_type="mpijobs")
        self.clear_jobs()

    def collect_nodes(self, gaudi_node_label):
        if self.hostfile:
            all_nodes = self.extract_host(self.hostfile)
        else:
            gaudi_label_id = f"{gaudi_node_label} -o=custom-columns='NAME:.metadata.name' --no-headers"

            cmd       = f"kubectl get nodes -l={gaudi_label_id}"
            output    = run_cmd(cmd)
            all_nodes = output.strip().split()

        _logger.info(f"Collected {len(all_nodes)} k8s Nodes: {all_nodes}")

        return all_nodes

    def initialize_node_jobs(self, level,
                             nodes,
                             job_base_path="tmp/jobs",
                             round=0):
        nodes_initialized = False
        update_val        = {
            "metadata-name": "",
            "round": round,
            "container-image": self.image,
            "num-nodes": "",
            "target-nodes": ""
        }

        if level == 1:
            source_f                   = "template/k8s/intel-gaudi-health-screen-L1.yaml"
            update_val["num-nodes"]    = len(nodes.all_nodes)
            update_val["target-nodes"] = nodes.all_nodes
            node_groups                = nodes.all_nodes
            job_path                   = f"{job_base_path}/L1"
            yaml_type                  = "job"
            metadata_app               = "ighs"
        elif level == 2:
            source_f                   = "template/k8s/intel-gaudi-health-screen-L2_hccl-demo.yaml"
            yaml_type                  = "mpijob"
            metadata_app               = "ighs-hccl"

            healthy_nodes = list(nodes.healthy_nodes.copy())
            watch_nodes   = list(nodes.watch_nodes.copy())

            node_groups, nodes.groups_tracker = find_groups(healthy_nodes, watch_nodes, nodes.groups_tracker)
            nodes.current_node_groups         = node_groups
            job_path                          = f"{job_base_path}/L2/r{round}"

        if len(node_groups) == 0 :
            _logger.warning(f"No Node Groups to test found during initialization")
            return nodes_initialized


        for i, node_group in enumerate(node_groups):
            if level == 1:
                update_val["metadata-name"] = f"ighs-{node_group}"
                update_val["target-nodes"]  = [node_group]
                out_file                    = f"{node_group}.yaml"
            elif level == 2:
                update_val["metadata-name"] = f"ighs-hccl-r{round}-{i}"
                update_val["target-nodes"]  = node_group
                update_val["num-nodes"]     = len(node_group)
                out_file                    = f"{update_val['metadata-name']}.yaml"

            self.update_yaml_job(source_file=source_f,
                                    update_val=update_val,
                                    out_dir=job_path,
                                    out_file=out_file,
                                    yaml_type=yaml_type)

        _logger.info(f"Launching Level {level} Jobs at {job_path}")
        cmd    = f"kubectl apply -f {job_path}"
        output = run_cmd(cmd)
        _logger.debug(f"Applying job output: {output}")

        # Launch Background process to copy IGHS Repo onto Pods
        cwd = os.getcwd()
        p   = multiprocessing.Process(target=self.cp_ighs, args=(self.namespace,cwd, metadata_app)) 
        p.start()

        nodes_initialized = True

        return nodes_initialized

    def cp_ighs(self, namespace, cwd, metadata_app):
        pods_done = dict()
        cmd       = f"kubectl get pods -n {namespace} -l app={metadata_app} -o=custom-columns='NAME:.metadata.name,STATUS:.status.phase' --no-headers"
        output    = run_cmd(cmd).strip()
        pods      = output.split("\n")

        # Copy IGHS Repos to running Containers
        while len(pods_done) < len(pods):
            cmd    = f"kubectl get pods -n {namespace} -l app={metadata_app} -o=custom-columns='NAME:.metadata.name,STATUS:.status.phase' --no-headers"
            output = run_cmd(cmd).strip()
            pods   = output.split("\n")

            for p in pods:
                p_name, state = p.split()
                if p_name not in pods_done and state == "Running":
                    cmd     = f"kubectl cp -n {namespace} {cwd} {p_name}:/workdir/intel_gaudi_health_screen"
                    output  = run_cmd(cmd).strip()

                    pods_done[p_name] = True

    def update_yaml_job(self, update_val={},
                        source_file="template/k8s/intel-gaudi-health-screen-L1.yaml",
                        out_dir="tmp/jobs",
                        out_file="default.yaml",
                        yaml_type="job"):
        with open(source_file, 'r') as f:
            template_data = yaml.safe_load(f)

        template_data["metadata"]["name"]      = update_val["metadata-name"]
        template_data["metadata"]["namespace"] = self.namespace

        if yaml_type == "job":
            replicas_specs                    = template_data["spec"]["template"]["spec"]

            replicas_specs["containers"][0]["image"]           = update_val["container-image"]
            replicas_specs["containers"][0]["name"]            = update_val["metadata-name"]
            replicas_specs["containers"][0]["env"].append({"name": "LOG_DIR", "value": self.log_dir})

            worker_selector_expression                         = replicas_specs["affinity"]["nodeAffinity"]["requiredDuringSchedulingIgnoredDuringExecution"]["nodeSelectorTerms"]
        elif yaml_type == "mpijob":
            replicas_specs                                                       = template_data["spec"]["mpiReplicaSpecs"]
            replicas_specs["Launcher"]["template"]["metadata"]["labels"]["name"] = update_val["metadata-name"]

            launcher_data                                      = replicas_specs["Launcher"]["template"]["spec"]
            launcher_data["containers"][0]["image"]            = update_val["container-image"]
            launcher_data["containers"][0]["env"].append({"name": "TARGET_NODES", "value": ','.join(update_val['target-nodes'])})
            launcher_data["containers"][0]["env"].append({"name": "LOG_DIR", "value": self.log_dir})
            launcher_data["containers"][0]["env"].append({"name": "ROUND", "value": f"r{update_val['round']}"})
            launcher_data["containers"][0]["env"].append({"name": "NUM_NODES", "value": f"{update_val['num-nodes']}"})

            replicas_specs["Worker"]["replicas"]               = update_val['num-nodes']
            worker_data                                        = replicas_specs["Worker"]["template"]["spec"]
            worker_data["containers"][0]["image"]              = update_val["container-image"]

            worker_selector_expression                         = worker_data["affinity"]["nodeAffinity"]["requiredDuringSchedulingIgnoredDuringExecution"]["nodeSelectorTerms"]

        worker_selector_expression[0]["matchExpressions"][0]["values"] = update_val["target-nodes"]

        out_f = f"{out_dir}/{out_file}"
        dir_name = os.path.dirname(out_f)
        if not os.path.exists(dir_name):
            os.makedirs(dir_name)

        with open(out_f, 'w+') as f:
            yaml.dump(template_data, f)

        _logger.info(f"Created Yaml: {out_f}")

        return out_f

    def clear_ighs_pods(self, job_type="jobs"):
        """ Clear Pods with label=ighs,ighs-hccl

        Args:
            job_type (str, optional): Type of Job to delete. Options: [jobs, mpijobs]. Defaults to "jobs".
        """
        _logger.info(f"Checking for existing IGHS Pods ({job_type})")

        metadata_app = "ighs" if (job_type == "jobs") else "ighs-hccl"

        cmd    = f"kubectl get pods -n {self.namespace} -l app={metadata_app} -o=custom-columns='NAME:.metadata.name' --no-headers"
        output = run_cmd(cmd).strip()

        if len(output) > 0:
            _logger.info(f"Found existing IGHS Pods ({job_type}). Will delete.")

            cmd     = f"kubectl get {job_type} -n {self.namespace} -l app={metadata_app} -o=custom-columns='NAME:.metadata.name' --no-headers"
            output  = run_cmd(cmd).strip()
            jobs    = output.split()

            _logger.info(f"Deleting jobs {jobs}")
            for job in jobs:
                cmd      = f"kubectl delete {job_type} -n {self.namespace} {job}"
                output   = run_cmd(cmd)

            cmd         = f"kubectl get pods -n {self.namespace} -l app={metadata_app} -o=custom-columns='NAME:.metadata.name' --no-headers"
            max_attempt = 15
            for attempts in range(max_attempt):
                output = run_cmd(cmd).strip()

                if len(output) == 0:
                    break

                _logger.info(f"Attempt {attempts}: Pods are still up. Will wait 5 seconds to check again")
                time.sleep(5)

    def check_screen_complete(self, current_run_status, health_report, level, round=0, job_path="tmp/jobs", final_check=False):
        if level == 1:
            metadata_app = "ighs"
            log_dir      = f"{self.log_dir}/L{level}"
        elif level == 2:
            metadata_app = "ighs-hccl"
            log_dir      = f"{self.log_dir}/L{level}/r{round}"

        if not os.path.exists(log_dir):
            os.makedirs(log_dir)

        cmd     = f"kubectl get pods -n {self.namespace} -l app={metadata_app} -o=custom-columns='NAME:.metadata.name,STATUS:.status.phase,STATE:status.containerStatuses[*].state.waiting.reason' --no-headers"
        output  = run_cmd(cmd).strip()
        pods    = output.split("\n")

        for p in pods:
            try:
                p_name, status, state = p.split()
                if status == "Succeeded":
                    cmd    = f"kubectl logs -n {self.namespace} {p_name}"
                    output = run_cmd(cmd).strip().split("\n")

                    start_analyze = False
                    for l in output:
                        if "START of Node Report" in l:
                            start_analyze = True
                            continue
                        elif "END of Node Report" in l:
                            start_analyze = False
                            continue
                        
                        #### analyze output
                        if start_analyze:
                            # Ignore Logger output level
                            bracket_index = l.index("{")
                            node_status_txt = l[bracket_index:]
                            status_dict = json.loads(node_status_txt)

                            if not p_name in current_run_status:
                                with open(f"{log_dir}/{p_name}.json", 'w', encoding ='utf8') as f:
                                    json.dump(status_dict, f, indent=4)
                                with open(f"{log_dir}/{p_name}.log", 'w', encoding ='utf8') as f:
                                    f.write('\n'.join(output))

                                if level == 1:
                                    health_report.write_rows(data=status_dict["cards"], level=level)
                                    current_run_status[p_name] = True
                                elif level == 2:
                                    health_report.write_rows(data=[status_dict], level=level)
                                    current_run_status[p_name] = (True, status_dict["num_nodes"])
                elif state == "CrashLoopBackOff" and level==2 or (final_check and "launcher" in p_name and status=="Running"):
                    cmd    = f"kubectl logs -n {self.namespace} {p_name}"
                    output = run_cmd(cmd).strip().split("\n")

                    hccL_results = hccl_demo_check(job_id=p_name, health_report=health_report, hccl_log=output, write=False)

                    if not p_name in current_run_status:
                        with open(f"{log_dir}/{p_name}.json", 'w', encoding ='utf8') as f:
                            json.dump(hccL_results, f, indent=4)
                        with open(f"{log_dir}/{p_name}.log", 'w', encoding ='utf8') as f:
                            f.write('\n'.join(output))

                        health_report.write_rows(data=[hccL_results], level=level)
                        current_run_status[p_name] = (True, hccL_results["num_nodes"])
            except ValueError:
                _logger.error(f"Not able to retrieve Running Pods. Expected to recieve list of pods but got output: {pods}")

        if level == 1:
            num_nodes = len(current_run_status)
        elif level == 2:
            num_nodes = 0

            # L2 runs MPIJobs that contains 2 nodes
            for k,v in current_run_status.items():
                num_nodes += v[1]

        return num_nodes

    def diagnose_missing_nodes(self, missing_nodes):
        in_use_set = set()
        missing_cards_set = set()
        misc_set = set()
        _logger.info(f"Diagnose {len(missing_nodes)} missing_nodes:")

        for n in missing_nodes:
            cmd        = f"kubectl describe nodes -n {self.namespace} {n}"
            output     = run_cmd(cmd).strip()
            output_arr = output.split("\n")

            reach_allocatable           = False
            reach_allocatable_resources = False
            for l in output_arr:
                if("Allocatable:" in l):
                    reach_allocatable = True
                if(reach_allocatable and "habana.ai/gaudi: " in l):
                    num_gaudis = int(l.split()[1])
                    if num_gaudis < 8:
                        missing_cards_set.add(n)
                        break

                if("Allocated resources:" in l):
                    reach_allocatable_resources = True
                if(reach_allocatable_resources and "habana.ai/gaudi" in l):
                    num_gaudis = int(l.split()[1])
                    if num_gaudis > 0:
                        in_use_set.add(n)
                        break

        in_use_list        = sorted(list(in_use_set))
        missing_cards_list = sorted(list(missing_cards_set))
        misc_list          = sorted(list(set(missing_nodes).difference(in_use_set).difference(missing_cards_set)))

        if(len(in_use_list)):
            _logger.info(f"  {len(in_use_list)} Occupied Nodes: {in_use_list}")
        if(len(missing_cards_list)):
            _logger.info(f"  {len(missing_cards_list)} Nodes w/ missing cards: {missing_cards_list}")
        if(len(misc_list)):
            _logger.info(f"  {len(misc_list)} Untested Nodes: {misc_list}")

        return in_use_list, missing_cards_list, misc_list


class BareMetalUtils(SystemUtils):

    def __init__(self,
                 image,
                 hostfile,
                 ssh_path,
                 tcp_interface,
                 log_dir,
                 docker_compose_f="template/intel-gaudi-docker-compose-L1.yaml"):
        super().__init__(image, log_dir, remote_path="/tmp/ighs")

        self.hostfile             = hostfile
        self.ssh_path             = ssh_path
        self.tcp_interface        = tcp_interface
        self.docker_compose_f     = docker_compose_f
        self.docker_compose_alias = "docker compose"

        self.hosts = self.extract_host(self.hostfile)

        os.environ["PDSH_RCMD_TYPE"] = "ssh"

        self.pdsh_cmd = f"pdsh -w ^{self.hostfile}"
        self.docker_compose_cmd = f"{self.pdsh_cmd} {self.docker_compose_alias}"

        self.initialize_ssh()

    def initialize_ssh(self):
        _logger.debug("Activating ssh-agent")
        cmd    = f"ssh-agent -s"
        output = run_cmd(cmd)
        _OUTPUT_PATTERN = re.compile(r'SSH_AUTH_SOCK=(?P<SSH_AUTH_SOCK>[^;]+).*SSH_AGENT_PID=(?P<SSH_AGENT_PID>\d+)', re.MULTILINE | re.DOTALL)
        match = _OUTPUT_PATTERN.search(output)
        data  = match.groupdict()
        os.environ['SSH_AUTH_SOCK'] = data['SSH_AUTH_SOCK']
        os.environ['SSH_AGENT_PID'] = data['SSH_AGENT_PID']

        _logger.debug("Adding ighs private key to ssh-agent")
        cmd    = f"ssh-add {self.ssh_path}/ighs_rsa"
        output = run_cmd(cmd)


    def initialize_system(self):
        _logger.info(f"Setting up ssh connection for hosts: {self.hosts}")
        for h in self.hosts:
            cmd    = f"ssh-copy-id -o StrictHostKeyChecking=no -i {self.ssh_path}/ighs_rsa.pub {os.environ['USER']}@{h}"
            output = run_cmd(cmd,verbose=True)

        self.clear_ighs_pods()
        self.clear_ighs_pods(job_type="mpijobs")
        self.clear_jobs()
        self.clear_remote_jobs()


        self.initialize_ssh()
        copy_files(src="../", dst=f"{self.remote_path}", exclude={"logs", "ssh", "tmp"}, hosts=self.hosts)


    def collect_nodes(self, gaudi_node_label=""):
        _logger.info(f"Collected {len(self.hosts)} Nodes: {self.hosts}")

        return self.hosts

    def initialize_node_jobs(self, level,
                             nodes,
                             job_base_path="tmp/jobs",
                             round=0):
        nodes_initialized = False
        update_val        = {
            "metadata-name": "",
            "round": round,
            "container-image": self.image,
            "num-nodes": "",
            "target-nodes": "",
            "master-node": ""
        }

        if level == 1:
            update_val["num-nodes"]    = len(nodes.all_nodes)
            update_val["target-nodes"] = nodes.all_nodes
            node_groups                = nodes.all_nodes
            job_path                   = f"{job_base_path}/L1"
        elif level == 2:
            healthy_nodes = list(nodes.healthy_nodes.copy())
            watch_nodes   = list(nodes.watch_nodes.copy())

            node_groups, nodes.groups_tracker = find_groups(healthy_nodes, watch_nodes, nodes.groups_tracker)
            nodes.current_node_groups         = node_groups
            job_path                          = f"{job_base_path}/L2/r{round}"
            nodes.launcher_nodes              = list()
            nodes.worker_nodes                = list()

        if len(node_groups) == 0:
            _logger.warning(f"No Node Groups to test found during initialization")
            return nodes_initialized

        self.update_yaml_job(source_file="config.yaml", out_dir="tmp", out_file="config.yaml", yaml_type="config")
        for i, node_group in enumerate(node_groups):
            if level == 1:
                update_val["metadata-name"] = f"{node_group}"
                update_val["target-nodes"]  = [node_group]

                self.update_yaml_job(update_val=update_val, out_dir=job_path)

                copy_files(src="tmp/jobs", dst=f"{self.remote_path}", hosts=update_val["target-nodes"])
                copy_files(src="template/bare-metal/dockerfile", dst=f"{self.remote_path}/jobs/L1", hosts=update_val["target-nodes"])
                copy_files(src="./ssh", dst=f"{self.remote_path}/jobs/L1", hosts=update_val["target-nodes"])
                copy_files(src="tmp/config.yaml", dst=f"{self.remote_path}/intel_gaudi_health_screen", hosts=update_val["target-nodes"])

            elif level == 2:
                update_val["metadata-name"] = f"ighs-hccl-r{round}-{i}"
                update_val["target-nodes"]  = node_group
                update_val["master-node"]   = node_group[0]
                update_val["num-nodes"]     = len(node_group)

                self.update_yaml_job(source_file="template/bare-metal/intel-gaudi-docker-compose-L2-launcher.yaml",
                                     update_val=update_val,
                                     out_dir=job_path,
                                     out_file=f"intel-gaudi-docker-compose-L2-launcher.yaml",
                                     yaml_type="mpijob_launcher")

                self.update_yaml_job(source_file="template/bare-metal/intel-gaudi-docker-compose-L2-worker.yaml",
                                     update_val=update_val,
                                     out_dir=job_path,
                                     out_file=f"intel-gaudi-docker-compose-L2-worker.yaml",
                                     yaml_type="mpijob_worker")
                nodes.launcher_nodes.append(node_group[0])
                nodes.worker_nodes.extend(node_group[1:])

                copy_files(src="tmp/jobs", dst=f"{self.remote_path}", hosts=update_val["target-nodes"])
                copy_files(src="template/bare-metal/dockerfile", dst=f"{self.remote_path}/jobs/L2/r{round}", hosts=update_val["target-nodes"])
                copy_files(src="template/bare-metal/ssh", dst=f"{self.remote_path}/jobs/L2/r{round}", hosts=update_val["target-nodes"])
                copy_files(src="tmp/config.yaml", dst=f"{self.remote_path}/intel_gaudi_health_screen", hosts=update_val["target-nodes"])


        _logger.info(f"Launching Level {level} Jobs at {job_path}")

        if level == 1:
            cmd    = f"{self.docker_compose_cmd} -f {self.remote_path}/jobs/L1/intel-gaudi-docker-compose-L1.yaml up"
            output = run_cmd(cmd).strip()
        elif level == 2:
            with open(f"{job_base_path}/L2/r{round}/hostfile_launchers", mode='wt', encoding='utf-8') as f:
                f.write('\n'.join(nodes.launcher_nodes))
            with open(f"{job_base_path}/L2/r{round}/hostfile_workers", mode='wt', encoding='utf-8') as f:
                f.write('\n'.join(nodes.worker_nodes))

            cmd_list = [
                f"pdsh -w ^{job_base_path}/L2/r{round}/hostfile_workers {self.docker_compose_alias} -f {self.remote_path}/jobs/L2/r{round}/intel-gaudi-docker-compose-L2-worker.yaml build",
                f"pdsh -w ^{job_base_path}/L2/r{round}/hostfile_workers {self.docker_compose_alias} -f {self.remote_path}/jobs/L2/r{round}/intel-gaudi-docker-compose-L2-worker.yaml up -d --remove-orphans",
                f"pdsh -w ^{job_base_path}/L2/r{round}/hostfile_launchers {self.docker_compose_alias} -f {self.remote_path}/jobs/L2/r{round}/intel-gaudi-docker-compose-L2-launcher.yaml build",
                f"pdsh -w ^{job_base_path}/L2/r{round}/hostfile_launchers {self.docker_compose_alias} -f {self.remote_path}/jobs/L2/r{round}/intel-gaudi-docker-compose-L2-launcher.yaml up -d --remove-orphans"
            ]

            for cmd in cmd_list:
                verbose = ("up" in cmd)
                output = run_cmd(cmd, verbose=verbose).strip()

        nodes_initialized = True

        return nodes_initialized

    def update_yaml_job(self,
                        source_file="template/bare-metal/intel-gaudi-docker-compose-L1.yaml",
                        out_dir="tmp/jobs",
                        out_file="intel-gaudi-docker-compose-L1.yaml",
                        update_val={},
                        yaml_type="job"):
        with open(source_file, 'r') as f:
            template_data = yaml.safe_load(f)

        if yaml_type == "job":
            template_data["services"]["ighs_level1"]["build"]["args"]["BASE_IMAGE"] = self.image

            template_data["services"]["ighs_level1"]["environment"].append(f"MY_NODE_NAME={update_val['metadata-name']}")
            template_data["services"]["ighs_level1"]["environment"].append(f"LOG_DIR={self.log_dir}")
        elif yaml_type == "mpijob_launcher":
            template_data["services"]["ighs_level2_launcher"]["build"]["args"]["BASE_IMAGE"] = self.image

            template_data["services"]["ighs_level2_launcher"]["environment"].append(f"MY_NODE_NAME={update_val['metadata-name']}")
            template_data["services"]["ighs_level2_launcher"]["environment"].append(f"LOG_DIR={self.log_dir}")
            template_data["services"]["ighs_level2_launcher"]["environment"].append(f"ROUND=r{update_val['round']}")
            template_data["services"]["ighs_level2_launcher"]["environment"].append(f"NUM_NODES={update_val['num-nodes']}")
            template_data["services"]["ighs_level2_launcher"]["environment"].append(f'TARGET_NODES={",".join(update_val["target-nodes"])}')
            template_data["services"]["ighs_level2_launcher"]["environment"].append(f"MASTER_ADDR={update_val['master-node']}")
            template_data["services"]["ighs_level2_launcher"]["environment"].append(f"TCP_INTERFACE={self.tcp_interface}")
            template_data["services"]["ighs_level2_launcher"]["environment"].append(f"JOB_ID={update_val['metadata-name']}")
        elif yaml_type == "mpijob_worker":
            template_data["services"]["ighs_level2_worker"]["build"]["args"]["BASE_IMAGE"] = self.image
            template_data["services"]["ighs_level2_worker"]["environment"].append(f"MY_NODE_NAME={update_val['metadata-name']}")
            template_data["services"]["ighs_level2_worker"]["environment"].append(f"LOG_DIR={self.log_dir}")
            template_data["services"]["ighs_level2_worker"]["environment"].append(f"JOB_ID={update_val['metadata-name']}")
        elif yaml_type == "config":
            hostfile                                 = template_data["system-info"]["hostfile"]
            ssh_path                                 = template_data["system-info"]["ssh-path"]
            template_data["system-info"]["hostfile"] = f"/tmp/ighs/intel_gaudi_health_screen/{os.path.basename(hostfile)}"
            template_data["system-info"]["ssh-path"] = f"/tmp/ighs/intel_gaudi_health_screen/{os.path.basename(ssh_path)}"

        out_f = f"{out_dir}/{out_file}"
        dir_name = os.path.dirname(out_f)
        if not os.path.exists(dir_name):
            os.makedirs(dir_name)

        with open(out_f, 'w+') as f:
            yaml.dump(template_data, f)

        _logger.info(f"Created Yaml: {out_f}")

    def clear_ighs_pods(self, job_type="jobs"):
        work_dir = f"{self.remote_path}/jobs"

        if job_type == "jobs":
            cmd    = f"{self.docker_compose_cmd} -f {work_dir}/L1/intel-gaudi-docker-compose-L1.yaml down"
            output = run_cmd(cmd).strip()
        else:
            files = glob.glob(f"{work_dir}/L2/**/*.yaml", recursive=True)
            _logger.debug(f"Files to clear: {files}")
            for f in files:
                dir_name = os.path.dirname(f)

                if "launcher" in f:
                    cmd  = f"pdsh -w ^{dir_name}/hostfile_launchers {self.docker_compose_alias} -f {f} down"
                elif "worker" in f:
                    cmd  = f"pdsh -w ^{dir_name}/hostfile_workers {self.docker_compose_alias} -f {f} down"

                output = run_cmd(cmd).strip()

    def clear_remote_jobs(self):
        cmd    = f"{self.pdsh_cmd} rm -R /tmp/ighs/jobs/"
        output = run_cmd(cmd)

    def check_screen_complete(self, current_run_status, health_report, level, round=0, job_path="tmp/jobs", final_check=False):
        docker_status_cmd = "ps -a --format json --filter status=exited"

        if level == 1:
            log_dir          = f"{self.log_dir}/L{level}"
            docker_compose_f = f"{self.remote_path}/jobs/L1/intel-gaudi-docker-compose-L1.yaml"
            cmd              = f"{self.docker_compose_cmd} -f {docker_compose_f} {docker_status_cmd}"
        elif level == 2:
            log_dir          = f"{self.log_dir}/L{level}/r{round}"
            docker_compose_f = f"{self.remote_path}/jobs/L2/r{round}/intel-gaudi-docker-compose-L2-launcher.yaml"
            cmd              = f"pdsh -w ^{job_path}/L2/r{round}/hostfile_launchers {self.docker_compose_alias} -f {docker_compose_f} {docker_status_cmd}"

        if not os.path.exists(log_dir):
            os.makedirs(log_dir)

        check_log_cmd = f"{self.docker_compose_alias} -f {docker_compose_f} logs"

        output = run_cmd(cmd).strip()
        pods   = output.split("\n")

        for p in pods:
            try:
                if ":" not in p:
                    continue

                colon_index = p.index(":")
                name = p[:colon_index]
                data_txt = p[colon_index+1:]

                data = json.loads(data_txt)

                if data["State"] == "exited":
                    cmd = f"ssh {name} {check_log_cmd}"
                    output = run_cmd(cmd).strip().split("\n")

                    start_analyze = False
                    for l in output:
                        if "START of Node Report" in l:
                            start_analyze = True
                            continue
                        elif "END of Node Report" in l:
                            start_analyze = False
                            continue

                        #### analyze output
                        if start_analyze:
                            # Ignore Logger output level
                            bracket_index = l.index("{")
                            node_status_txt = l[bracket_index:]
                            status_dict = json.loads(node_status_txt)

                            if not name in current_run_status:
                                if level == 1:
                                    health_report.write_rows(data=status_dict["cards"], level=level)
                                    current_run_status[name] = True
                                elif level == 2:
                                    health_report.write_rows(data=[status_dict], level=level)
                                    current_run_status[name] = (True, status_dict["num_nodes"])
                                    name = f"ighs-hccl-r{status_dict['round']}-{status_dict['group_id']}"

                                with open(f"{log_dir}/{name}.json", 'w', encoding ='utf8') as f:
                                    json.dump(status_dict, f, indent=4)
                                with open(f"{log_dir}/{name}.log", 'w', encoding ='utf8') as f:
                                    f.write('\n'.join(output))
                elif level==2 and final_check:
                    cmd = f"ssh {name} {check_log_cmd}"
                    output = run_cmd(cmd).strip().split("\n")

                    if not name in current_run_status:
                        hccL_results = hccl_demo_check(job_id=name, health_report=health_report, hccl_log=output, write=False)
                        f_name = f"ighs-hccl-r{hccL_results['round']}-{hccL_results['group_id']}"

                        with open(f"{log_dir}/{f_name}.json", 'w', encoding ='utf8') as f:
                            json.dump(hccL_results, f, indent=4)
                        with open(f"{log_dir}/{f_name}.log", 'w', encoding ='utf8') as f:
                            f.write('\n'.join(output))

                        health_report.write_rows(data=[hccL_results], level=level)
                        current_run_status[name] = (True, hccL_results["num_nodes"])
            except:
                _logger.error(f"Not able to retrieve Running Pods. Expected to recieve list of pods but got output: {pods}")

        if level == 1:
            num_nodes = len(current_run_status)
        elif level == 2:
            num_nodes = 0

            # L2 runs MPIJobs that contains 2 nodes
            for k,v in current_run_status.items():
                num_nodes += v[1]

        return num_nodes

    def diagnose_missing_nodes(self, missing_nodes):
        return [],[],[]
