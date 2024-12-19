###############################################################################
# Copyright (C) 2022 Habana Labs, Ltd. an Intel Company
# All Rights Reserved.
#
# Unauthorized copying of this file or any element(s) within it, via any medium
# is strictly prohibited.
# This file contains Habana Labs, Ltd. proprietary and confidential information
# and is subject to the confidentiality and license agreements under which it
# was provided.
#
###############################################################################

import argparse
import os
import concurrent.futures

def parse_arguments():
    parser = argparse.ArgumentParser(description="Check health of Intel Gaudi for PyTorch")

    parser.add_argument("--cards",
                        default=1,
                        type=int,
                        required=False,
                        help="Set number of cards to test (default: 1)")

    args = parser.parse_args()
    print(f"Configuration: {args}")

    return args

def pytorch_test(device_id=0):
    """ Checks health of Intel Gaudi through running a basic
    PyTorch example on Intel Gaudi

    Args:
        device_id (int, optional): ID of Intel Gaudi. Defaults to 0.
    """

    os.environ["HLS_MODULE_ID"] = str(device_id)
    os.environ["HABANA_VISIBLE_MODULES"] = str(device_id)

    try:
        import torch
        import habana_frameworks.torch.core
    except Exception as e:
        print(f"Card {device_id} Failed to initialize Intel Gaudi PyTorch: {str(e)}")
        raise

    try:
        x = torch.tensor([2]).to('hpu')
        y = x + x

        assert y == 4, 'Sanity check failed: Wrong Add output'
        assert 'hpu' in y.device.type.lower(), 'Sanity check failed: Operation not executed on Intel Gaudi Card'
    except (RuntimeError, AssertionError) as e:
        print(f"Card Module ID {device_id} Failure: {e}")
        raise

    return device_id

if __name__ == '__main__':
    args = parse_arguments()
    passed_cards = set()

    with concurrent.futures.ProcessPoolExecutor() as executor:
        futures = [executor.submit(pytorch_test, device_id) for device_id in range(args.cards)]
        for future in concurrent.futures.as_completed(futures):
            try:
                dev_id = future.result()
                passed_cards.add(dev_id)
                print(f"Card module_id {dev_id} PASSED")

            except Exception as e:
                print(f"Failed to initialize on Intel Gaudi, error: {str(e)}")

    failed_cards =  set(range(args.cards)) - passed_cards

    print(f"Failed cards Module ID: {failed_cards}")
    print(f"Passed cards Module ID: {passed_cards}")