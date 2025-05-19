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

import os, time, csv, json
import logging
import multiprocessing

from HealthReport import HealthReport
from utilities import run_cmd, create_logger

_logger = logging.getLogger("health_screener")


class IGNodes():

    def __init__(self, health_report=HealthReport()):
        """ Keeps Track of Nodes and their current states

        Args:
            health_report (HealthReport, optional): IGHS Health Report. Defaults to creating a new HealthReport().
        """
        self.all_nodes           = list()
        self.launcher_nodes      = list()
        self.worker_nodes        = list()
        self.healthy_nodes       = set()
        self.watch_nodes         = set()
        self.infected_nodes      = set()
        self.missing_nodes       = set()

        self.groups_tracker      = list()
        self.current_node_groups = list()

        self.health_report       = health_report
        self.log_dir             = health_report.f_dir

    def update_node_status(self, healthy_nodes, infected_nodes, missing_nodes, undetected_nodes=[]):
        """Update the node lists status based on current node groups. If a node
        paring fails with known healthy node, then the other node is considered
        infected. Otherwise it will be moved to the healthy node list

        Args:
            healthy_nodes ([str]): List of Healthy nodes that pass IGHS testing
            infected_nodes ([str]): List of nodes that failed to pass IGHS testing
            missing_nodes ([str]): List of nodes that IGHS did not run testing on
            undetected_nodes ([str]): List of nodes that IGHS did not run testing on b/c it wasn't scheduled on
        """
        watch_nodes       = self.watch_nodes.copy()

        # Remove Nodes that haven't been tested yet from the healthy list
        for n in undetected_nodes:
            if n in watch_nodes and n in healthy_nodes:
                healthy_nodes.remove(n)

        self.healthy_nodes.update(healthy_nodes)

        for group in self.current_node_groups:
            n1, n2 = group
            self.determine_node_health(infected_nodes, missing_nodes, n1, n2)
            self.determine_node_health(infected_nodes, missing_nodes, n2, n1)

        self.watch_nodes  = self.watch_nodes.difference(self.healthy_nodes)

    def determine_node_health(self, infected_nodes, missing_nodes, n1, n2):
        """Determine whether a node is healthy .

        Args:
            infected_nodes ([str]): List of nodes that failed to pass IGHS testing
            missing_nodes ([str]): List of nodes that IGHS did not run testing on
            n1 (str): Node name to investigate if it passes the IGHS test
            n2 (str): Node name that should be considered healthy. This assist in verifying status of N1
        """
        if n2 in self.healthy_nodes:
            remove_from_watch = False

            if n1 in infected_nodes:
                self.infected_nodes.add(n1)
                remove_from_watch = True
            if n1 in missing_nodes:
                self.missing_nodes.add(n1)
                remove_from_watch = True

            if remove_from_watch and n1 in self.watch_nodes:
                self.watch_nodes.remove(n1)

class IGNode():

    def __init__(self, name="", health_report=HealthReport(), num_checks_link_state=10, log_level=logging.INFO, write_dir="/tmp/ighs"):
        self.name = name
        if name == "" and "MY_NODE_NAME" in os.environ:
            self.name = os.environ["MY_NODE_NAME"]

        self.cards                   = dict()
        self.num_checks_link_state   = num_checks_link_state
        self.write_dir               = write_dir
        if(not os.path.exists(self.write_dir)):
            os.makedirs(self.write_dir)

        self.health_report           = health_report
        if not self.health_report.exist():
            self.health_report.create()

        self.logger, _ = create_logger(logger_name=self.name, logger_file_name=self.name, f_path=f"{write_dir}", level=log_level)


    def scan_cards(self):
        self.logger.info(f"Scanning cards info on Node: {self.name}")

        cmd = "hl-smi -Q index,module_id,bus_id,memory.used,temperature.aip,name -f csv,noheader"
        output = run_cmd(cmd)

        reader = csv.reader(output.split('\n'), delimiter=',')
        for row in reader:
            if len(row) == 0:
                continue
            elif len(row) < 6:
                _logger.error(f"hl-smi output is not correct: Recieved output: {row}")
                continue

            i             = row[0]
            module_id     = row[1].strip()
            pci_address   = row[2]
            memory_used   = int(row[3].split()[0])
            temperature_C = int(row[4].split()[0])
            system_name   = row[5]

            card = IGCard(system_name=system_name, index=i, module_id=module_id, pci_address=pci_address, memory_used=memory_used, temperature=temperature_C, logger=self.logger)
            self.cards[i] = card

        self.cards = dict(sorted(self.cards.items()))

    def record_dmesg(self):
        cmd    = f"dmesg -T"
        output = run_cmd(cmd)

        self.logger.info("***** START of DMESG *****")
        self.logger.info(output)
        self.logger.info("***** END of DMESG *****")

    def health_check(self, target_cards=[], write_report=False):
        checked_cards = list()
        processes     = list()
        card_queue    = multiprocessing.Queue()

        if len(target_cards) == 0:
            target_cards = self.cards.keys()

        for i in target_cards:
            card = self.cards[str(i)]
            p = multiprocessing.Process(target=card.check_health, args=(self.num_checks_link_state,card_queue)) 

            p.start()
            processes.append((card,p))

        for card,p in processes:
            p.join()
        card_queue.put(None)

        for card in iter(card_queue.get, None):
            card.node_id = self.name
            checked_cards.append(card)
            self.logger.info(card)

        self.record_dmesg()
        checked_cards_dict = self.write_json(checked_cards)
        if(write_report):
            self.health_report.write_rows(data=checked_cards_dict)

    def write_json(self, cards):
        node_status = dict()
        node_status["name"]        = self.name
        node_status["is_infected"] = False
        node_status["cards"]       = list()

        for c in cards:
            c_status = c.__dict__
            del c_status["logger"]
            node_status["cards"].append(c.__dict__)

            if c.is_infected:
                node_status["is_infected"] = True
        
        self.logger.info("***** START of Node Report *****")
        self.logger.info(json.dumps(node_status))
        self.logger.info("***** END of Node Report *****")

        return node_status["cards"]

class IGCard():

    def __init__(self, system_name="", index=-1, module_id=-1, pci_address="", memory_used=-1, framework="pytorch", temperature=-1, logger=None):
        self.system_name               = system_name
        self.node_id                   = ""
        self.logger                    = logger
        self.index                     = index
        self.module_id                 = module_id
        self.pci_address               = pci_address
        self.memory_used               = memory_used
        self.temperature_C             = temperature
        self.temperature_state_C       = ""

        self.framework                 = framework
        self.down_links                = list()
        self.device_acquire_fail       = False
        self.multi_node_fail           = False
        self.is_infected               = False

        self.internal_ports            = list()
        self.external_ports            = list()

    def check_health(self,num_checks_link_state=10, checked_cards=[]):
        self.check_port_type()
        self.check_link_state(attempts=num_checks_link_state, sleep_sec=0.2)
        self.check_device_acquire_fail()
        self.check_temperature_state()

        checked_cards.put(self)

    def check_link_state(self, attempts=10, sleep_sec=0.5):
        self.logger.debug(f"Checking {self.pci_address} Link State. Will check {attempts} times")
        all_ports = self.internal_ports + self.external_ports
        all_ports_txt = ",".join(all_ports)

        cmd = f"hl-smi -n link -i {self.pci_address} -P {all_ports_txt}"
        down_links = set()

        for a in range(attempts):
            output = run_cmd(cmd)
            links_state = output.strip().split("\n")

            for i, status in enumerate(links_state):
                if ("DOWN" in status):
                    down_links.add(i)
                    self.logger.debug(f"Attempt: {a} Port: {i} DOWN")
                    self.is_infected = True

            time.sleep(sleep_sec)

        self.down_links = list(down_links)

        return self.down_links


    def check_port_type(self):
        self.logger.debug(f"Checking {self.pci_address} Port Types (Internal|External)")

        cmd    = f"hl-smi -n ports -i {self.pci_address}"
        output = run_cmd(cmd)
        output_list = output.strip().split("\n")

        for output in output_list:
            port_txt, port_type = output.split(":")
            port = port_txt.split(" ")[1]

            if "external" in port_type:
                self.external_ports.append(port)
            else:
                self.internal_ports.append(port)

    def check_device_acquire_fail(self):
        self.logger.debug(f"Checking {self.pci_address} for Device Acquire Issues")
        self.device_acquire_fail = False

        os.environ["ID"] = str(self.module_id)
        os.environ["HABANA_VISIBLE_MODULES"] = str(self.module_id)

        try:
            import torch
            import habana_frameworks.torch.core
        except Exception as e:
            self.logger.error(f"Card {self.module_id} {self.pci_address} Failed to initialize Intel Gaudi PyTorch: {str(e)}")
            self.device_acquire_fail  = True
            self.is_infected = True

        try:
            x = torch.tensor([2]).to('hpu')
            y = x + x

            assert y == 4, 'Sanity check failed: Wrong Add output'
            assert 'hpu' in y.device.type.lower(), 'Sanity check failed: Operation not executed on Habana Device'
        except (RuntimeError, AssertionError, Exception) as e:
            self.logger.error(f"{self.pci_address} Device Acquire Failure: {e}")
            self.device_acquire_fail  = True
            self.is_infected = True

        return self.device_acquire_fail

    def check_temperature_state(self):
        if "HL-325" in self.system_name:
            # Gaudi-3 System
            max_good_temperature = 200
            base_temperature     = 45
            max_delta            = 80
        else:
            # Gaudi-2 System
            max_good_temperature = 83
            base_temperature     = 25
            max_delta            = 25
            

        if self.temperature_C >= max_good_temperature:
            self.temperature_state_C = "CRITICAL"
            self.is_infected = True
        elif abs(self.temperature_C - base_temperature) >= max_delta:
            self.temperature_state_C = "WARN"
            self.is_infected = True
        else:
            self.temperature_state_C = "NORMAL"

    def __str__(self):
        report_str = f""" Index: {self.index}
                            Module Id: {self.module_id}
                            PCI Address: {self.pci_address}
                            Temperature: {self.temperature_C} C
                            Temperature State: {self.temperature_state_C}
                            Down Links: {self.down_links}
                            Device Acquire Fail: {self.device_acquire_fail}"""

        return report_str

