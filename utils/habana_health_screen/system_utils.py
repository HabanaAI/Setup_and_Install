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

import time, os, shutil, yaml, glob
import logging

from utilities import run_cmd, copy_files
from hccl_demo_helper import find_groups, gather_hccl_logs


_logger = logging.getLogger("habana_health_screener")


class SystemUtils():

    def __init__(self, image, log_dir, remote_path="/tmp/hhs"):
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

    def monitor_hhs_status(self, level, nodes, timeout_s=240, round=0, monitor=True):
        is_finished  = False
        attempt      = 0
        max_attempts = (timeout_s // 10) + min(timeout_s % 10, 1)
        hccl_demo    = (level == 2)

        if len(nodes.healthy_nodes) > 0:
            num_nodes = len(nodes.healthy_nodes)
        else:
            num_nodes = len(nodes.all_nodes)

        _logger.info(f"Checking HHS Level {level} Status")

        if monitor:
            for attempt in range(max_attempts):
                is_finished, num_found_nodes = nodes.health_report.check_screen_complete(num_nodes=num_nodes, hccl_demo=hccl_demo, round=round)

                if is_finished:
                    _logger.info(f"Found {num_found_nodes}/{num_nodes} Nodes during Health Screen")

                    # Gives time for cleanup between rounds
                    time.sleep(10)
                    break

                _logger.info(f"Attempt {attempt}/{max_attempts}: Found {num_found_nodes}/{num_nodes} Nodes - Will Check again in 10 seconds")
                time.sleep(10)

            if level == 2:
                gather_hccl_logs(job_path=self.job_path,
                                 round=round,
                                 log_dir=self.log_dir,
                                 health_report=nodes.health_report)

        else:
            hosts = nodes.all_nodes
            if len(nodes.launcher_nodes) > 0:
                hosts = nodes.launcher_nodes

            nodes.health_report.gather_health_report(level, remote_path="/tmp/hhs", hosts=hosts)
            nodes.health_report.consolidate_health_report(level=level, report_dir=f"{self.log_dir}")

        if level == 1:
            detected_nodes, infected_nodes, missing_nodes = nodes.health_report.extract_node_info()
            missing_nodes.update(set(nodes.all_nodes).difference(detected_nodes))

            nodes.health_report.update_health_report(detected_nodes=detected_nodes, infected_nodes=infected_nodes, missing_nodes=missing_nodes)
        elif level == 2:
            detected_nodes, infected_nodes, missing_nodes = nodes.health_report.extract_hccl_demo_info()
            nodes.health_report.update_health_report(detected_nodes=detected_nodes, infected_nodes=infected_nodes, missing_nodes=missing_nodes)

            detected_nodes_l1, infected_nodes_l1, missing_nodes = nodes.health_report.extract_node_info()
            detected_nodes.update(detected_nodes_l1)
            infected_nodes.update(infected_nodes_l1)

        healthy_nodes  = detected_nodes.difference(infected_nodes).difference(missing_nodes)

        healthy_nodes  = sorted(list(healthy_nodes))
        missing_nodes  = sorted(list(missing_nodes))
        infected_nodes = sorted(list(infected_nodes))
        detected_nodes = sorted(list(detected_nodes))

        if level == 1:
            nodes.healthy_nodes = healthy_nodes

        _logger.info(f"Infected {len(infected_nodes)} Node: {infected_nodes}")
        _logger.info(f"Missing {len(missing_nodes)} Node: {missing_nodes}")
        _logger.info(f"Healthy {len(healthy_nodes)} Node: {healthy_nodes}")
        _logger.info(f"Detected {len(detected_nodes)} Node: {detected_nodes}")

        return healthy_nodes, infected_nodes, missing_nodes


class KubeUtils(SystemUtils):

    def __init__(self, image, hostfile, namespace, log_dir):
        super().__init__(image, log_dir)
        self.namespace = namespace
        self.hostfile = hostfile

    def initialize_system(self):
        self.clear_hhs_pods()
        self.clear_hhs_pods(job_type="mpijobs")
        self.clear_jobs()

    def collect_nodes(self, gaudi_node_label):
        if self.hostfile:
            all_nodes = self.extract_host(self.hostfile)
        else:
            gaudi_label_id = f"{gaudi_node_label} -o=custom-columns='NAME:.metadata.name' --no-headers"

            cmd       = f"kubectl get nodes -l={gaudi_label_id}"
            output    = run_cmd(cmd)
            all_nodes = output.strip().split()

        _logger.info(f"Collected Nodes: {all_nodes}")

        return all_nodes

    def initialize_node_jobs(self, level,
                             nodes,
                             job_base_path="tmp/jobs",
                             round=0):
        update_val = {
            "metadata-name": "",
            "round": round,
            "container-image": self.image,
            "num-nodes": "",
            "target-nodes": ""
        }

        if level == 1:
            source_f                   = "template/k8s/pt-habana-health-screen-L1.yaml"
            update_val["num-nodes"]    = len(nodes.all_nodes)
            update_val["target-nodes"] = nodes.all_nodes
            node_groups                = nodes.all_nodes
            job_path                   = f"{job_base_path}/L1"
            yaml_type                  = "job"
        elif level == 2:
            source_f                   = "template/k8s/pt-habana-health-screen-L2_hccl-demo.yaml"
            yaml_type                  = "mpijob"

            if len(nodes.healthy_nodes) > 0:
                nodes_to_test = nodes.healthy_nodes
            else:
                nodes_to_test = nodes.all_nodes.copy()

            node_groups, nodes.groups_tracker = find_groups(nodes_to_test, nodes.groups_tracker)
            job_path                    = f"{job_base_path}/L2/r{round}"

        for i, node_group in enumerate(node_groups):
            if level == 1:
                update_val["metadata-name"] = f"hhs-{node_group}"
                update_val["target-nodes"]  = [node_group]
                out_file                    = f"{node_group}.yaml"
            elif level == 2:
                update_val["metadata-name"] = f"hhs-hccl-r{round}-{i}"
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


    def update_yaml_job(self, update_val={},
                        source_file="template/k8s/pt-habana-health-screen-L1.yaml",
                        out_dir="tmp/jobs",
                        out_file="default.yaml",
                        yaml_type="job"):
        with open(source_file, 'r') as f:
            template_data = yaml.safe_load(f)

        template_data["metadata"]["name"]      = update_val["metadata-name"]
        template_data["metadata"]["namespace"] = self.namespace

        if yaml_type == "job":
            replicas_specs                    = template_data["spec"]["template"]["spec"]

            replicas_specs["volumes"][0]["hostPath"]["path"]   = os.getcwd()
            replicas_specs["containers"][0]["image"]           = update_val["container-image"]
            replicas_specs["containers"][0]["name"]            = update_val["metadata-name"]
            replicas_specs["containers"][0]["env"].append({"name": "LOG_DIR", "value": self.log_dir})

            worker_selector_expression                         = replicas_specs["affinity"]["nodeAffinity"]["requiredDuringSchedulingIgnoredDuringExecution"]["nodeSelectorTerms"]
        elif yaml_type == "mpijob":
            replicas_specs                                                       = template_data["spec"]["mpiReplicaSpecs"]
            replicas_specs["Launcher"]["template"]["metadata"]["labels"]["name"] = update_val["metadata-name"]

            launcher_data                                      = replicas_specs["Launcher"]["template"]["spec"]
            launcher_data["volumes"][0]["hostPath"]["path"]    = os.getcwd()
            launcher_data["containers"][0]["image"]            = update_val["container-image"]
            launcher_data["containers"][0]["env"].append({"name": "TARGET_NODES", "value": ','.join(update_val['target-nodes'])})
            launcher_data["containers"][0]["env"].append({"name": "LOG_DIR", "value": self.log_dir})
            launcher_data["containers"][0]["env"].append({"name": "ROUND", "value": f"r{update_val['round']}"})
            launcher_data["containers"][0]["env"].append({"name": "NUM_NODES", "value": f"{update_val['num-nodes']}"})

            replicas_specs["Worker"]["replicas"]               = update_val['num-nodes']
            worker_data                                        = replicas_specs["Worker"]["template"]["spec"]
            worker_data["volumes"][0]["hostPath"]["path"]      = os.getcwd()
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

    def clear_hhs_pods(self, job_type="jobs"):
        """ Clear Pods with label=hhs,hhs-hccl

        Args:
            job_type (str, optional): Type of Job to delete. Options: [jobs, mpijobs]. Defaults to "jobs".
        """
        _logger.info(f"Checking for existing HHS Pods ({job_type})")

        metadata_app = "hhs" if (job_type == "jobs") else "hhs-hccl"

        cmd    = f"kubectl get pods -n {self.namespace} -l app={metadata_app} -o=custom-columns='NAME:.metadata.name' --no-headers"
        output = run_cmd(cmd).strip()

        if len(output) > 0:
            _logger.info(f"Found existing HHS Pods ({job_type}). Will delete.")

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

                _logger.info(f"Attempt {attempts}: Pods are still up. Will wait 10 seconds to check again")
                time.sleep(10)

    def diagnose_unhealthy_nodes(self, infected_nodes, missing_nodes):
        in_use_set = set()
        missing_cards_set = set()
        misc_set = set()

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
            _logger.info(f"{len(in_use_list)} Occupied Nodes: {in_use_list}")
        if(len(missing_cards_list)):
            _logger.info(f"{len(missing_cards_list)} Nodes w/ missing cards: {missing_cards_list}")
        if(len(misc_list)):
            _logger.info(f"{len(misc_list)} Unaccounted Nodes: {misc_list}")



class BareMetalUtils(SystemUtils):

    def __init__(self,
                 image,
                 hostfile,
                 ssh_path,
                 tcp_interface,
                 log_dir,
                 docker_compose_f="template/pt-hhs-docker-compose-L1.yaml"):
        super().__init__(image, log_dir, remote_path="/tmp/hhs")

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

        _logger.debug("Adding hhs private key to ssh-agent")
        cmd    = f"ssh-add {self.ssh_path}/hhs_rsa"
        output = run_cmd(cmd)


    def initialize_system(self):
        self.clear_hhs_pods()
        self.clear_hhs_pods(job_type="mpijobs")
        self.clear_jobs()
        self.clear_remote_jobs()

        _logger.info(f"Setting up ssh connection for hosts: {self.hosts}")
        for h in self.hosts:
            cmd    = f"ssh-copy-id -o StrictHostKeyChecking=no -i {self.ssh_path}/hhs_rsa.pub {os.environ['USER']}@{h}"
            output = run_cmd(cmd)

        self.initialize_ssh()
        copy_files(src="../", dst=f"{self.remote_path}", exclude={"logs", "ssh", "tmp"}, hosts=self.hosts)


    def collect_nodes(self, gaudi_node_label=""):
        _logger.info(f"Collected Nodes: {self.hosts}")

        return self.hosts

    def initialize_node_jobs(self, level,
                             nodes,
                             job_base_path="tmp/jobs",
                             round=0):
        update_val = {
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
            if len(nodes.healthy_nodes) > 0:
                nodes_to_test = [n.replace("hhs-","").replace(":48","") for n in nodes.healthy_nodes]
            else:
                nodes_to_test = nodes.all_nodes.copy()

            node_groups, nodes.groups_tracker = find_groups(nodes_to_test, nodes.groups_tracker)
            job_path                          = f"{job_base_path}/L2/r{round}"
            nodes.launcher_nodes              = list()
            nodes.worker_nodes                = list()

        self.update_yaml_job(source_file="config.yaml", out_dir="tmp", out_file="config.yaml", yaml_type="config")
        for i, node_group in enumerate(node_groups):
            if level == 1:
                update_val["metadata-name"] = f"{node_group}"
                update_val["target-nodes"]  = [node_group]

                self.update_yaml_job(update_val=update_val, out_dir=job_path)

                copy_files(src="tmp/jobs", dst=f"{self.remote_path}", hosts=update_val["target-nodes"])
                copy_files(src="template/bare-metal/dockerfile", dst=f"{self.remote_path}/jobs/L1", hosts=update_val["target-nodes"])
                copy_files(src="./ssh", dst=f"{self.remote_path}/jobs/L1", hosts=update_val["target-nodes"])
                copy_files(src="tmp/config.yaml", dst=f"{self.remote_path}/habana_health_screen", hosts=update_val["target-nodes"])

            elif level == 2:
                update_val["metadata-name"] = f"hhs-hccl-r{round}-{i}"
                update_val["target-nodes"]  = node_group
                update_val["master-node"]   = node_group[0]
                update_val["num-nodes"]     = len(node_group)

                self.update_yaml_job(source_file="template/bare-metal/pt-hhs-docker-compose-L2-launcher.yaml",
                                     update_val=update_val,
                                     out_dir=job_path,
                                     out_file=f"pt-hhs-docker-compose-L2-launcher.yaml",
                                     yaml_type="mpijob_launcher")

                self.update_yaml_job(source_file="template/bare-metal/pt-hhs-docker-compose-L2-worker.yaml",
                                     update_val=update_val,
                                     out_dir=job_path,
                                     out_file=f"pt-hhs-docker-compose-L2-worker.yaml",
                                     yaml_type="mpijob_worker")
                nodes.launcher_nodes.append(node_group[0])
                nodes.worker_nodes.extend(node_group[1:])

                copy_files(src="tmp/jobs", dst=f"{self.remote_path}", hosts=update_val["target-nodes"])
                copy_files(src="template/bare-metal/dockerfile", dst=f"{self.remote_path}/jobs/L2/r{round}", hosts=update_val["target-nodes"])
                copy_files(src="template/bare-metal/ssh", dst=f"{self.remote_path}/jobs/L2/r{round}", hosts=update_val["target-nodes"])
                copy_files(src="tmp/config.yaml", dst=f"{self.remote_path}/habana_health_screen", hosts=update_val["target-nodes"])


        _logger.info(f"Launching Level {level} Jobs at {job_path}")

        if level == 1:
            cmd    = f"{self.docker_compose_cmd} -f {self.remote_path}/jobs/L1/pt-hhs-docker-compose-L1.yaml up"
            output = run_cmd(cmd).strip()
        elif level == 2:
            with open(f"{job_base_path}/L2/r{round}/hostfile_launchers", mode='wt', encoding='utf-8') as f:
                f.write('\n'.join(nodes.launcher_nodes))
            with open(f"{job_base_path}/L2/r{round}/hostfile_workers", mode='wt', encoding='utf-8') as f:
                f.write('\n'.join(nodes.worker_nodes))

            cmd_list = [
                f"pdsh -w ^{job_base_path}/L2/r{round}/hostfile_workers {self.docker_compose_alias} -f {self.remote_path}/jobs/L2/r{round}/pt-hhs-docker-compose-L2-worker.yaml build",
                f"pdsh -w ^{job_base_path}/L2/r{round}/hostfile_workers {self.docker_compose_alias} -f {self.remote_path}/jobs/L2/r{round}/pt-hhs-docker-compose-L2-worker.yaml up -d --remove-orphans",
                f"pdsh -w ^{job_base_path}/L2/r{round}/hostfile_launchers {self.docker_compose_alias} -f {self.remote_path}/jobs/L2/r{round}/pt-hhs-docker-compose-L2-launcher.yaml build",
                f"pdsh -w ^{job_base_path}/L2/r{round}/hostfile_launchers {self.docker_compose_alias} -f {self.remote_path}/jobs/L2/r{round}/pt-hhs-docker-compose-L2-launcher.yaml up --remove-orphans"
            ]

            for cmd in cmd_list:
                output = run_cmd(cmd).strip()

    def update_yaml_job(self,
                        source_file="template/bare-metal/pt-hhs-docker-compose-L1.yaml",
                        out_dir="tmp/jobs",
                        out_file="pt-hhs-docker-compose-L1.yaml",
                        update_val={},
                        yaml_type="job"):
        with open(source_file, 'r') as f:
            template_data = yaml.safe_load(f)

        if yaml_type == "job":
            template_data["services"]["hhs_level1"]["build"]["args"]["BASE_IMAGE"] = self.image

            template_data["services"]["hhs_level1"]["environment"].append(f"MY_NODE_NAME={update_val['metadata-name']}")
            template_data["services"]["hhs_level1"]["environment"].append(f"LOG_DIR={self.log_dir}")
        elif yaml_type == "mpijob_launcher":
            template_data["services"]["hhs_level2_launcher"]["build"]["args"]["BASE_IMAGE"] = self.image

            template_data["services"]["hhs_level2_launcher"]["environment"].append(f"MY_NODE_NAME={update_val['metadata-name']}")
            template_data["services"]["hhs_level2_launcher"]["environment"].append(f"LOG_DIR={self.log_dir}")
            template_data["services"]["hhs_level2_launcher"]["environment"].append(f"ROUND=r{update_val['round']}")
            template_data["services"]["hhs_level2_launcher"]["environment"].append(f"NUM_NODES={update_val['num-nodes']}")
            template_data["services"]["hhs_level2_launcher"]["environment"].append(f'TARGET_NODES={",".join(update_val["target-nodes"])}')
            template_data["services"]["hhs_level2_launcher"]["environment"].append(f"MASTER_ADDR={update_val['master-node']}")
            template_data["services"]["hhs_level2_launcher"]["environment"].append(f"TCP_INTERFACE={self.tcp_interface}")
            template_data["services"]["hhs_level2_launcher"]["environment"].append(f"JOB_ID={update_val['metadata-name']}")
        elif yaml_type == "mpijob_worker":
            template_data["services"]["hhs_level2_worker"]["build"]["args"]["BASE_IMAGE"] = self.image
            template_data["services"]["hhs_level2_worker"]["environment"].append(f"MY_NODE_NAME={update_val['metadata-name']}")
            template_data["services"]["hhs_level2_worker"]["environment"].append(f"LOG_DIR={self.log_dir}")
            template_data["services"]["hhs_level2_worker"]["environment"].append(f"JOB_ID={update_val['metadata-name']}")
        elif yaml_type == "config":
            hostfile                                 = template_data["system-info"]["hostfile"]
            ssh_path                                 = template_data["system-info"]["ssh-path"]
            template_data["system-info"]["hostfile"] = f"/tmp/hhs/habana_health_screen/{os.path.basename(hostfile)}"
            template_data["system-info"]["ssh-path"] = f"/tmp/hhs/habana_health_screen/{os.path.basename(ssh_path)}"

        out_f = f"{out_dir}/{out_file}"
        dir_name = os.path.dirname(out_f)
        if not os.path.exists(dir_name):
            os.makedirs(dir_name)

        with open(out_f, 'w+') as f:
            yaml.dump(template_data, f)

        _logger.info(f"Created Yaml: {out_f}")

    def monitor_hhs_status(self, level, nodes, timeout_s=240, round=0, monitor=True):
        return super().monitor_hhs_status(level=level, nodes=nodes, timeout_s=timeout_s, round=round, monitor=False)

    def clear_hhs_pods(self, job_type="jobs"):
        work_dir = f"{self.remote_path}/jobs"

        if job_type == "jobs":
            cmd    = f"{self.docker_compose_cmd} -f {work_dir}/L1/pt-hhs-docker-compose-L1.yaml down"
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
        cmd    = f"{self.pdsh_cmd} rm -R /tmp/hhs/jobs/"
        output = run_cmd(cmd)

    def diagnose_unhealthy_nodes(self, infected_nodes, missing_nodes):
        pass
