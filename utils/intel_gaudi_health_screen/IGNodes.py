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

import os, time, csv
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
        self.all_nodes      = list()
        self.launcher_nodes = list()
        self.worker_nodes   = list()
        self.healthy_nodes  = list()
        self.infected_nodes = list()

        self.groups_tracker = list()

        self.health_report  = health_report
        self.log_dir        = health_report.f_dir



class IGNode():

    def __init__(self, name="", health_report=HealthReport(), num_checks_link_state=10, log_level=logging.INFO):
        self.name = name
        if name == "" and "MY_NODE_NAME" in os.environ:
            self.name = os.environ["MY_NODE_NAME"]

        self.cards                   = dict()
        self.num_checks_link_state   = num_checks_link_state

        self.health_report           = health_report
        if not self.health_report.exist():
            self.health_report.create()

        self.logger, _ = create_logger(logger_name=self.name, logger_file_name=self.name, f_path=f"{health_report.f_dir}/L1", level=log_level)


    def scan_cards(self):
        self.logger.info(f"Scanning cards info on Node: {self.name}")

        cmd = "hl-smi -Q index,module_id,bus_id,memory.used,temperature.aip -f csv,noheader"
        output = run_cmd(cmd)

        reader = csv.reader(output.split('\n'), delimiter=',')
        for row in reader:
            if len(row) == 0:
                continue

            i             = row[0]
            module_id     = row[1].strip()
            pci_address   = row[2]
            memory_used   = int(row[3].split()[0])
            temperature_C = int(row[4].split()[0])

            card = IGCard(index=i, module_id=module_id, pci_address=pci_address, memory_used=memory_used, temperature=temperature_C, logger=self.logger)
            self.cards[i] = card

        self.cards = dict(sorted(self.cards.items()))

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
            checked_cards.append(card)
            self.logger.info(card)

        if(write_report):
            self.health_report.write_rows(node_id=self.name, cards=checked_cards)


class IGCard():

    def __init__(self, index=-1, module_id=-1, pci_address="", memory_used=-1, framework="pytorch", temperature=-1, logger=None):
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

        self.external_ports            = [1, 8, 9]
        self.incorrect_ports_direction = list()

    def check_health(self,num_checks_link_state=10, checked_cards=[]):
        self.check_link_state(attempts=num_checks_link_state, sleep_sec=0.2)
        self.check_device_acquire_fail()
        self.check_temperature_state()

        checked_cards.put(self)

    def check_link_state(self, attempts=10, sleep_sec=0.5):
        self.logger.debug(f"Checking {self.pci_address} Link State. Will check {attempts} times")
        cmd = f"hl-smi -n link -i {self.pci_address}"
        down_links = set()

        for a in range(attempts):
            output = run_cmd(cmd)
            links_state = output.strip().split("\n")

            for i, status in enumerate(links_state):
                if ("DOWN" in status):
                    down_links.add(i)
                    self.logger.debug(f"Attempt: {a} Port: {i} DOWN")

            time.sleep(sleep_sec)

        self.down_links = list(down_links)

        return self.down_links


    def check_port_direction(self):
        self.logger.debug(f"Checking {self.pci_address} Port Directions")

        incorrect_ports_direction = list()
        cmd    = f"hl-smi -n ports -i {self.pci_address}"
        output = run_cmd(cmd)

        ports_direction = output.strip().split("\n")
        if ports_direction[-1] == "":
            ports_direction.pop()

        for i, direction in enumerate(ports_direction):
            if i in self.external_ports:
                if "internal" in direction:
                    incorrect_ports_direction.append(i)
            else:
                if "external" in direction:
                    incorrect_ports_direction.append(i)

        self.incorrect_ports_direction = incorrect_ports_direction

        return incorrect_ports_direction

    def check_device_acquire_fail(self):
        self.logger.debug(f"Checking {self.pci_address} for Device Acquire Issues")
        self.device_acquire_fail = False

        os.environ["ID"] = str(self.module_id)

        try:
            import torch
            import habana_frameworks.torch.core
        except Exception as e:
            self.logger.error(f"Card {self.module_id} {self.pci_address} Failed to initialize Intel Gaudi PyTorch: {str(e)}")
            self.device_acquire_fail  = True

        try:
            x = torch.tensor([2]).to('hpu')
            y = x + x

            assert y == 4, 'Sanity check failed: Wrong Add output'
            assert 'hpu' in y.device.type.lower(), 'Sanity check failed: Operation not executed on Habana Device'
        except (RuntimeError, AssertionError, Exception) as e:
            self.logger.error(f"{self.pci_address} Device Acquire Failure: {e}")
            self.device_acquire_fail  = True

        return self.device_acquire_fail

    def check_temperature_state(self):
        max_good_temperature = 83
        base_temperature     = 25
        max_delta            = 25

        if self.temperature_C >= max_good_temperature:
            self.temperature_state_C = "CRITICAL"
        elif self.temperature_C - base_temperature >= max_delta:
            self.temperature_state_C = "WARN"
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

