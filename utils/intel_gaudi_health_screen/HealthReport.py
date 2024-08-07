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

import os, csv, time, shutil, fcntl, glob, copy
from collections import defaultdict
from tempfile import NamedTemporaryFile

from utilities import copy_files

import logging

_logger = logging.getLogger("health_screener")

class HealthReport():

    def __init__(self, f_dir="tmp", report_name="health_report.csv"):
        """ Initialize Health Report Class

        Args:
            f_dir (str, optional): File Directory to store Health Report logs and results. Defaults to "tmp".
            report_name (str, optional): File name of Health Report csv. Defaults to "health_report.csv".
        """
        self.header           = ["node_id", "index", "module_id", "pci_address", "temperature_C", "temperature_state_C", "device_acquire_fail", "down_links", "multi_node_fail", "missing"]

        self.f_dir            = f_dir
        self.report_name      = report_name
        self.f_path           = f"{self.f_dir}/{self.report_name}"

        self.header_hccl_demo = ["round","group_id", "node_ids", "num_nodes", "multi_node_fail", "missing", "qpc_fail"]
        self.f_path_hccl_demo = f"{self.f_dir}/{os.path.splitext(self.report_name)[0]}_hccl_demo.csv"


    def create(self, create_base=True, create_hccl_demo=False):
        """Create CSV Health Report Files. One for Base Health Checks and HCCL Demo Checks

        Args:
            create_base (bool, optional): Create Base Health_Report CSV file. Defaults to True.
            create_hccl_demo (bool, optional): Create HCCL_DEMO_Health_Report if it doesn't exist. Defaults to False.
        """

        dir_name = os.path.dirname(self.f_path)
        if not os.path.exists(dir_name):
            os.makedirs(dir_name)

        if create_base:
            with open(self.f_path, "w+", newline='') as f:
                writer = csv.DictWriter(f, fieldnames=self.header, extrasaction='ignore')
                writer.writeheader()
            _logger.info(f"Created {self.f_path} with header: {self.header}")

        if create_hccl_demo and not self.exist(level=2):
            with open(self.f_path_hccl_demo, "w+", newline='') as f:
                writer = csv.DictWriter(f, fieldnames=self.header_hccl_demo, extrasaction='ignore')
                writer.writeheader()
            _logger.info(f"Created {self.f_path_hccl_demo} with header: {self.header_hccl_demo}")

    def exist(self, level=1):
        """Checks to see if Base Health Report exist

        Args:
            level (int, optional): Health Screen level report csv to check. Defaults to 1.

        Returns:
            bool: Returns True if the Base Health Report (self.f_path) or HCCL_DEMO Health Report (self.f_path_hccl_demo) exist
        """
        f_path = self.f_path

        if level == 2:
            f_path = self.f_path_hccl_demo

        return os.path.exists(f_path)

    def write_rows(self, data=list(), level=1):
        """ Write health check results to Health Report CSV. Can write multiple rows at once

        Args:
            data (_type_, optional): Health Report CSV Row data. Defaults to list().
            level (int, optional): Health Screen Level. Defaults to 1.
        """

        if level == 1:
            f_path = self.f_path
            header = self.header


        elif level == 2:
            f_path = self.f_path_hccl_demo
            header = self.header_hccl_demo

        with open(f_path, "a", newline='') as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            writer = csv.DictWriter(f, fieldnames=header, extrasaction='ignore')
            writer.writerows(data)
            time.sleep(0.1)
            fcntl.flock(f, fcntl.LOCK_UN)

    def update_health_report(self, detected_nodes, infected_nodes, missing_nodes):
        """ Update health_report with hccl_demo results

        Args:
            detected_nodes (list[str]): List of detected node_ids
            infected_nodes (list[str]): List of infected node_ids
            missing_nodes (list[str]): List of missing node_ids
        """
        temp_file = NamedTemporaryFile(mode='w', delete=False)
        detected_nodes_cp = detected_nodes.copy()

        with open(self.f_path, 'r', newline='') as csv_file, temp_file:
            reader     = csv.DictReader(csv_file)
            writer     = csv.DictWriter(temp_file, fieldnames=self.header)

            writer.writeheader()
            for row in reader:
                if row["node_id"] in infected_nodes or row["node_id"] in missing_nodes:
                    row["multi_node_fail"] = True
                elif row["node_id"] in detected_nodes_cp:
                    row["multi_node_fail"] = False
                    row["missing"] = False

                writer.writerow(row)

                missing_nodes.discard(row["node_id"])
                detected_nodes_cp.discard(row["node_id"])

            # These are unreported Detected Nodes. Add to Report
            if len(detected_nodes_cp):
                for n in detected_nodes_cp:
                    writer.writerow({"node_id": n, "multi_node_fail": False, "missing": False})

            # These are unreported Missing Nodes. Add to Report
            if len(missing_nodes):
                for n in missing_nodes:
                    writer.writerow({"node_id": n, "multi_node_fail": True, "missing": True})

        shutil.move(temp_file.name, self.f_path)

    def update_hccl_demo_health_report(self, round, all_node_pairs, multi_node_fail, qpc_fail, missing_nodes):
        """ Update health_report with hccl_demo results, based on infected_nodes.

        Args:
            all_node_pairs (list[str]): List of all Node Pairs reported by Level 2 round
            multi_node_fail (list[str]): List of Node Pairs that failed HCCL_Demo Test
            qpc_fail (list[str]): List of Node Pairs that failed HCCL_Demo Test due to QPC error
            missing_nodes (list[str]): List of Node Pairs that couldn't run HCCL_Demo
        """
        temp_file = NamedTemporaryFile(mode='w', delete=False)

        with open(self.f_path_hccl_demo, 'r', newline='') as csv_file, temp_file:
            reader     = csv.DictReader(csv_file)
            writer     = csv.DictWriter(temp_file, fieldnames=self.header_hccl_demo, extrasaction='ignore')

            writer.writeheader()
            for row in reader:
                if(row["round"] == round):
                    row["multi_node_fail"] = (row["node_ids"] in multi_node_fail)
                    row["qpc_fail"]        = (row["node_ids"] in qpc_fail)
                    row["missing"]         = (row["node_ids"] in missing_nodes)

                if row["node_ids"] in all_node_pairs:
                    del all_node_pairs[row["node_ids"]]

                writer.writerow(row)

            # These are unreported node_pairs. Add remaining node pairs
            if len(all_node_pairs):
                writer.writerows(list(all_node_pairs.values()))

        shutil.move(temp_file.name, self.f_path_hccl_demo)

    def check_screen_complete(self, num_nodes, hccl_demo=False, round=0):
        """ Check on status of Health Screen Check.
        Screen considered done if all nodes health checks are done

        Args:
            num_nodes (int): Number of Nodes screened
            hccl_demo (bool, optional): Status of HCCL_DEMO all reduce test. Defaults to False.
            round (int, optional): Level 2 Round. This will only check Level 2 round results. This is ignored for Level 1 runs.

        Returns:
            bool: Status of Screen. If all nodes are found, screening is done
        """
        f_path           = self.f_path if (not hccl_demo) else self.f_path_hccl_demo
        n_cards_per_node = 8

        with open(f_path, "r", newline='') as f:
            reader = csv.DictReader(f)

            if hccl_demo:
                n_cards = 0
                for row in reader:
                    if(int(row["round"]) == round):
                        n_cards += (int(row["num_nodes"]) * n_cards_per_node)
            else:
                n_cards = len(list(reader))

        total_cards        = n_cards_per_node * num_nodes
        has_all_nodes_info = (n_cards == total_cards)
        num_found_nodes    = n_cards // n_cards_per_node

        return has_all_nodes_info, num_found_nodes

    def extract_node_info(self):
        """ Extracts Detected, Infected, and Missing Nodes from Health Report.

        Returns:
            (set, set, set):  (Detected Nodes, Infected Nodes, Missing Nodes)
        """
        detected_nodes          = set()
        missing_nodes           = set()
        device_acquire_fail_set = set()
        down_links_set          = set()
        temperature_fail_set    = set()
        temperature_warn_set    = set()

        with open(self.f_path, "r", newline='') as f:
            reader = csv.DictReader(f)
            for row in reader:
                detected_nodes.add(row["node_id"])

                if row["device_acquire_fail"] == "True":
                    device_acquire_fail_set.add(row["node_id"])
                if row["down_links"] != "[]" and row["down_links"] != "":
                    down_links_set.add(row["node_id"])
                if row["missing"] == "True":
                    missing_nodes.add(row["node_id"])
                if row["temperature_state_C"] == "CRITICAL":
                    temperature_fail_set.add(row["node_id"])
                if row["temperature_state_C"] == "WARN":
                    temperature_warn_set.add(row["node_id"])

        if(len(device_acquire_fail_set)):
            _logger.info(f"{len(device_acquire_fail_set)} Infected (Device Acquire fail): {sorted(list(device_acquire_fail_set))}")
        if(len(down_links_set)):
            _logger.info(f"{len(down_links_set)} Infected (Down Links): {sorted(list(down_links_set))}")
        if(len(temperature_warn_set)):
            _logger.info(f"{len(temperature_warn_set)} Infected (Temperature WARN): {sorted(list(temperature_warn_set))}")
        if(len(temperature_fail_set)):
            _logger.info(f"{len(temperature_fail_set)} Infected (Temperature CRITICAL): {sorted(list(temperature_fail_set))}")

        infected_nodes = set()
        infected_nodes.update(device_acquire_fail_set)
        infected_nodes.update(down_links_set)
        infected_nodes.update(temperature_fail_set)
        infected_nodes.update(temperature_warn_set)

        return detected_nodes, infected_nodes, missing_nodes


    def extract_hccl_demo_info(self):
        """ Extracts Detected, Infected, and Missing Nodes from HCCL DEMO Health Report

        Returns:
            (set, set, set):  (Detected Nodes, Infected Nodes, Missing Nodes)
        """
        detected_nodes = set()
        infected_nodes = set()
        missing_nodes  = set()
        fail_checks    = defaultdict(list)
        missing_checks = defaultdict(list)

        with open(self.f_path_hccl_demo, "r", newline='') as f:
            reader = csv.DictReader(f)
            for row in reader:
                node_ids = row["node_ids"].strip("[']").replace("'","").split(', ')
                detected_nodes.update(node_ids)

                for n in node_ids:
                    fail_status = int(row["multi_node_fail"] == "True")
                    fail_checks[n].append(fail_status)

                    missing_status = int(row["missing"] == "True")
                    missing_checks[n].append(missing_status)

        for n, v in fail_checks.items():
            if sum(v) == len(v):
                infected_nodes.add(n)

        for n, v in missing_checks.items():
            if sum(v) == len(v):
                missing_nodes.add(n)

        detected_nodes -= missing_nodes
        infected_nodes -= missing_nodes

        _logger.info(f"{len(infected_nodes)} Infected (HCCL): {sorted(list(infected_nodes))}")

        return detected_nodes, infected_nodes, missing_nodes

    def gather_health_report(self, level, remote_path, hosts):
        """ Gathers Health Report from all hosts

        Args:
            level (str): IGHS Level
            remote_path (str): Remote Destintation of IGHS Report
            hosts (list, optional): List of IP Addresses to gather IGHS Reports
        """
        copy_files(src=f"{remote_path}/intel_gaudi_health_screen/{self.f_dir}/L{level}",
                        dst=f"{self.f_dir}",
                        hosts=hosts,
                        to_remote=False)

    def consolidate_health_report(self, level, report_dir):
        """ Consolidates the health_report_*.csv from worker pods into a single master csv file

        Args:
            level (str): IGHS Level
            report_dir (str): Directory of CSV files to merge
        """
        data      = list()
        path      = f"{report_dir}/L{level}/health_report_*.csv"
        csv_files = glob.glob(path)

        for f in csv_files:
            with open(f, 'r', newline='') as csv_file:
                reader = csv.DictReader(csv_file)
                for row in reader:
                    data.append(row)

        self.write_rows(data=data, level=level)

