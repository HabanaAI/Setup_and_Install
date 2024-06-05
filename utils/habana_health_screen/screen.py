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

import os, datetime, shutil, yaml, sys
import argparse
import logging

from utilities import download_repos, clear_hhs_pods, create_logger, get_logging_level
from hccl_demo_helper import hccl_demo_check
from system_utils import KubeUtils, BareMetalUtils

from HabanaHealthReport import HabanaHealthReport
from HNodes import HNodes, HNode


_logger = None


def main(args):
    global _logger

    if args.logs_dir == "":
        c_time           = datetime.datetime.now()
        date_year_format = c_time.strftime("%m-%Y")
        date_format      = c_time.strftime("%m-%d-%Y")
        time_format      = c_time.strftime("%H-%M")
        args.logs_dir    = f"logs/{date_year_format}/{date_format}/{date_format}_{time_format}"


    hhs_report_name = "health_report.csv"
    hhs_log_dir     = args.logs_dir

    if args.node_name:
        hhs_level       = os.environ["HHS_LEVEL"]
        hhs_report_name = f"health_report_{args.node_name}.csv"
        hhs_log_dir     = f"{args.logs_dir}/L{hhs_level}"

    health_report = HabanaHealthReport(f_dir=hhs_log_dir, report_name=hhs_report_name)
    job_path      = "tmp/jobs"

    with open(args.config, 'r') as f:
        config_data = yaml.safe_load(f)

    log_level  = get_logging_level(config_data["log-level"])
    _logger, _ = create_logger(logger_name="habana_health_screener", logger_file_name="screener", f_path=args.logs_dir, level=log_level)

    if config_data["system-info"]["type"] == "k8s":
        system_mode = KubeUtils(image=config_data["image"],
                                hostfile=config_data["system-info"]["hostfile"],
                                namespace=config_data["system-info"]["namespace"],
                                log_dir=args.logs_dir)
    elif config_data["system-info"]["type"] == "bare-metal":

        system_mode = BareMetalUtils(image=config_data["image"],
                                     hostfile=config_data["system-info"]["hostfile"],
                                     ssh_path=config_data["system-info"]["ssh-path"],
                                     tcp_interface=config_data["system-info"]["tcp-interface"],
                                     log_dir=args.logs_dir)
    else:
        _logger.error(f"system_mode: {system_mode} in {args.config} is not set correctly. system_mode has to be set to k8s or bare-metal")
        sys.exit(1)


    if args.initialize:
        _logger.info(f"Loaded Configuration File: {args.config}")
        _logger.info(f"{config_data}")

        health_report.create(create_base=True, create_hccl_demo=True)
        download_repos()

        system_mode.initialize_system()

    if args.screen:
        start_time = datetime.datetime.now()

        habana_nodes = HNodes(health_report=health_report)
        habana_nodes.all_nodes = system_mode.collect_nodes(gaudi_node_label=config_data["gaudi-node-label"])

        if config_data["level-1"]["run"]:
            _logger.info("Running Level 1 Checks: Card Diagnostics")
            if not os.path.exists(f"{health_report.f_dir}/L1"):
                os.makedirs(f"{health_report.f_dir}/L1")

            system_mode.initialize_node_jobs(level=1,
                                             nodes=habana_nodes,
                                             job_base_path=job_path)
            healthy_nodes, infected_nodes, missing_nodes = system_mode.monitor_hhs_status(level=1,
                                                                          nodes=habana_nodes,
                                                                          timeout_s=config_data["level-1"]["timeout_s"])
            system_mode.diagnose_unhealthy_nodes(infected_nodes, missing_nodes)

            system_mode.clear_hhs_pods()

        if config_data["level-2"]["run"]:
            _logger.info("Running Level 2 Checks: Pair HCCL_DEMO All Reduce")
            if not os.path.exists(f"{health_report.f_dir}/L2"):
                os.makedirs(f"{health_report.f_dir}/L2")

            for i in range(config_data["level-2"]["num-rounds"]):
                system_mode.initialize_node_jobs(level=2,
                                                 nodes=habana_nodes,
                                                 job_base_path=job_path,
                                                 round=i)
                healthy_nodes, infected_nodes, missing_nodes = system_mode.monitor_hhs_status(level=2,
                                                                               nodes=habana_nodes,
                                                                               timeout_s=config_data["level-2"]["timeout_s"],
                                                                               round=i)
                system_mode.diagnose_unhealthy_nodes(infected_nodes, missing_nodes)

                system_mode.clear_hhs_pods(job_type="mpijobs")

                if len(infected_nodes) == 0:
                    _logger.info(f"Round {i}/{config_data['level-2']['num-rounds']}: No Infected Nodes found. Exit screening early.")
                    break


        end_time  = datetime.datetime.now()
        diff_time = (end_time - start_time)
        _logger.info(f"Total Run Time: {diff_time}")

    if args.hhs_check == "node":
        node = HNode(health_report=health_report,
                     num_checks_link_state=config_data["level-1"]["num-checks-link-state"],
                     log_level=log_level)
        node.scan_cards()
        node.health_check(write_report=args.node_write_report)
    elif args.hhs_check == "hccl-demo":
        health_report.create(create_base=False, create_hccl_demo=True)

        target_nodes = args.target_nodes.strip("[']").replace("'","").split(',')
        hccl_demo_check(job_id=f"{health_report.f_dir}/L2/{args.round}/{args.job_id}",
                        target_nodes=target_nodes, health_report=health_report)

if __name__=="__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("--initialize", action="store_true", help="Downloads Necessary Repos and Creates Report Template")
    parser.add_argument("--screen", action="store_true", help="Starts Health Screen for Cluster")
    parser.add_argument("--target-nodes", type=str, default="", help="List of target nodes")
    parser.add_argument("--job-id", type=str, default="", help="Needed to identify hccl-demo running log")
    parser.add_argument("--round", type=str, default="", help="Needed to identify hccl-demo running round log")
    parser.add_argument("--config", type=str, default="config.yaml", help="Configuration file for Health Screener")
    parser.add_argument("--hhs-check", default="none", const="none", nargs="?", choices=["node", "hccl-demo", "none"],
        help="Check HHS Status for Node (Ports status, Device Acquire Fail) or all_reduce (HCCL_DEMO between paris of nodes)")

    parser.add_argument("--node-write-report", action="store_true", help="Write Individual Node Health Report")
    parser.add_argument("--node-name", type=str, default="", help="Name of Node")
    parser.add_argument("--logs-dir", type=str, default="", help="Output directory of health screen results")

    args = parser.parse_args()


    main(args)
