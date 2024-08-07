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

    os.environ["ID"] = str(device_id)

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
        print(f"Card {device_id} Failure: {e}")
        raise


if __name__ == '__main__':
    args = parse_arguments()

    try:
        with concurrent.futures.ProcessPoolExecutor() as executor:
            for device_id, res in zip(range(args.cards), executor.map(pytorch_test, range(args.cards))):
                print(f"Card {device_id} PASSED")
    except Exception as e:
            print(f"Failed to initialize on Intel Gaudi, error: {str(e)}")
            print(f"Check FAILED")
            exit(1)

    print(f"Check PASSED for {args.cards} cards")