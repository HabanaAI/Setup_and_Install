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

import os, time, sys
import subprocess, shlex
from datetime import datetime

import logging
from logging import handlers

_logger = logging.getLogger("health_screener")

def get_logging_level(log_level):
    log_level = log_level.lower()
    num_level = logging.INFO

    if log_level == "info":
        num_level = logging.INFO
    elif log_level == "debug":
        num_level = logging.DEBUG
    elif log_level == "warn":
        num_level = logging.WARN
    elif log_level == "error":
        num_level = logging.ERROR
    elif log_level == "critical":
        num_level = logging.CRITICAL

    return num_level

def create_logger(logger_name, logger_file_name, f_path="", level=logging.INFO, max_bytes=5e6, backup_count=10):
    """ Creates Logger that writes to logs directory

    Args:
        logger_name (str): Name of Logger File. Will be appended with logs/{current_time}/logger_name.log
        level (int, optional): Logging Level. Defaults to logging.INFO.
        max_bytes (int, optional): Max size of log file. Will rollover once maxed reach. Defaults to 5e6.
        backup_count (int, optional): Rollover Limit. Defaults to 10.

    Returns:
        logger: Logger Object used to log details to designated logger file
    """
    t_logger  = logging.getLogger(logger_name)
    t_logger.setLevel(level)

    c_time = datetime.now()
    date_format = c_time.strftime("%m-%d-%Y")
    time_format = c_time.strftime("%H-%M")

    file_path = f"{f_path}/{logger_file_name}.log" if f_path != "" else f"logs/{date_format}/{date_format}_{time_format}/{logger_file_name}.log"
    d_path    = os.path.dirname(file_path)
    _logger.debug(f"d_path: {d_path} file_path: {file_path}")

    if(not os.path.exists(d_path)):
        os.makedirs(d_path)

    formatter = logging.Formatter("[%(asctime)s] %(levelname)s %(message)s",datefmt='%Y-%m-%d %H:%M:%S')
    handler   = logging.handlers.RotatingFileHandler(file_path, maxBytes=max_bytes, backupCount=backup_count)
    handler.setFormatter(formatter)

    stream_handler = logging.StreamHandler(sys.stdout)
    stream_handler.setFormatter(formatter)

    t_logger.addHandler(handler)
    t_logger.addHandler(stream_handler)

    return t_logger, d_path

def run_cmd(cmd, timeout_s=900, verbose=False):
    """ Run Command through subprocess.run()

    Args:
        cmd (str): CMD to run
        timeout_s (int, optional): Timeout of CMD. Defaults to 1_800.
        verbose (bool, optional): Print results. Defaults to False

    Returns:
        bool: Result of CMD. If it encounters any weird exceptions it will be flagged as False
    """

    cmd = shlex.split(cmd)
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=timeout_s)

    if (verbose):
        _logger.debug(f"Running cmd: {cmd}")
        _logger.debug(result.stdout)

    return result.stdout

def download_repos():
    """ Download HCCL_DEMO Repo to assist in health checks
    """
    if not os.path.exists("build"):
        os.makedirs("build")

    if not os.path.exists("build/hccl_demo"):
        _logger.info(f"Downloading hccl_demo into build/")
        cmd = "git clone https://github.com/HabanaAI/hccl_demo.git build/hccl_demo"
        run_cmd(cmd)

        os.environ["MPI"]="1"
        cmd = "make -C build/hccl_demo"
        run_cmd(cmd)

def copy_files(src, dst, to_remote=True, hosts=[], exclude={}):
    """ Copies files through rsync from src to dst over the list of hosts

    Args:
        src (str): Source file/directory to copy
        dst (str): Destination to copy files/directory
        to_remote (bool, optional): rsync to remote destination (src -> host:dst). False will rsync to local destination (h:src -> dst). Defaults to True.
        hosts (list, optional): List of IP Addresses to copy to/from. Defaults to [].
        exclude (dict, optional): Files/Directory to ignore. Follow rsync rules for exclusions. Defaults to {}.
    """
    rsync_cmd = f"rsync -ahzgop --exclude={exclude}"

    for h in hosts:
        if (to_remote):
            src_path = src
            dst_path = f"{h}:{dst}"
        else:
            src_path = f"{h}:{src}"
            dst_path = dst

        _logger.debug(f"Copying {src_path} to {dst_path}")
        cmd    = f"{rsync_cmd} {src_path} {dst_path}"
        output = run_cmd(cmd)


def clear_job(job):
    """ Clear MPIJobs based on Job Name

    Args:
        job (str): Job Name to delete
    """
    _logger.info(f"Checking for existing MPIJobs {job}")
    cmd = f"kubectl get mpijobs -n default {job} -o=custom-columns='NAME:.metadata.name' --no-headers"
    output = run_cmd(cmd)

    if job in output:
        _logger.info(f"Found MPIJobs {job}. Will delete.")
        cmd = f"kubectl delete mpijobs -n default {job}"
        output = run_cmd(cmd)

        cmd = f"kubectl get pods -n default --selector=training.kubeflow.org/job-name={job} -o=custom-columns='NAME:.metadata.name' --no-headers"

        max_attempt = 15
        for attempts in range(max_attempt):
            output = run_cmd(cmd).strip()

            if(len(output) == 0):
                break

            _logger.info(f"Attempt {attempts} Pods are still up. Will wait 10 seconds to check again")
            time.sleep(10)
