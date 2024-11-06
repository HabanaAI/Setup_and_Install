import glob
import os
import shutil
import time

import soundfile
import torch
from habana_frameworks.torch.hpu import wrap_in_hpu_graph
from optimum.habana.checkpoint_utils import get_repo_root
from optimum.habana.transformers.modeling_utils import adapt_transformers_to_gaudi
from optimum.habana.utils import check_optimum_habana_min_version, set_seed
from transformers import AutoModelForSpeechSeq2Seq, AutoProcessor, pipeline
from transformers.utils import check_min_version


def read_audio(audio_file_path):
    audio_array, sample_rate = soundfile.read(audio_file_path)
    return audio_array, sample_rate


def override_print(enable):
    import builtins as __builtin__

    builtin_print = __builtin__.print

    def print(*args, **kwargs):
        force = kwargs.pop("force", False)
        if force or enable:
            builtin_print(*args, **kwargs)

    __builtin__.print = print


def override_logger(logger, enable):
    logger_info = logger.info

    def info(*args, **kwargs):
        force = kwargs.pop("force", False)
        if force or enable:
            logger_info(*args, **kwargs)

    logger.info = info


def count_hpu_graphs():
    return len(glob.glob(".graph_dumps/*PreGraph*"))


def override_prints(enable, logger):
    override_print(enable)
    override_logger(logger, enable)


def setup_env(args):
    """
    Need to test periodically if any breaking change is introduced in Optimum Habana ,  Transformers
    Might work with lower versions as well but not tested
    """
    check_min_version("4.45.2")
    check_optimum_habana_min_version("1.14.0.dev0")

    if args.global_rank == 0:
        os.environ.setdefault("GRAPH_VISUALIZATION", "true")
        shutil.rmtree(".graph_dumps", ignore_errors=True)

    if args.world_size > 0:
        os.environ.setdefault("PT_HPU_LAZY_ACC_PAR_MODE", "0")
        os.environ.setdefault("PT_HPU_ENABLE_LAZY_COLLECTIVES", "true")

    # Tweak generation so that it runs faster on Gaudi
    adapt_transformers_to_gaudi()


def setup_device(args):
    if args.device == "hpu":
        import habana_frameworks.torch.core as htcore
    return torch.device(args.device)


def setup_distributed_model(args, model_dtype, model_kwargs, logger):
    """
    TO BE IMPLEMENTED
    """
    raise Exception("Distributed model using Deepspeed yet to be implemented")
    return


def load_model(
    model_name_or_path, model_dtype, model_kwargs, logger, use_hpu_graphs=True
):
    logger.info(f"Loading model : {model_name_or_path}")

    model = AutoModelForSpeechSeq2Seq.from_pretrained(
        model_name_or_path,
        torch_dtype=model_dtype,
        low_cpu_mem_usage=False,
        use_safetensors=True,
    )  # , attn_implementation="sdpa",
    # **model_kwargs)
    model = model.eval().to("hpu")
    if use_hpu_graphs:
        model = wrap_in_hpu_graph(model)
    return model


def load_processor(model_name_or_path, logger):
    logger.info(f"Loading processor : {model_name_or_path}")
    processor = AutoProcessor.from_pretrained(model_name_or_path)
    return processor


def initialize_model_n_processor(args, logger):
    init_start = time.perf_counter()
    override_prints(args.global_rank == 0 or args.verbose_workers, logger)
    setup_env(args)
    setup_device(args)
    set_seed(args.seed)
    get_repo_root(args.model_name_or_path, local_rank=args.local_rank, token=args.token)

    if args.bf16:
        model_dtype = torch.bfloat16
    elif args.fp8:
        raise Exception("fp8 precision yet to be supported. Please try bf16")
    else:
        model_dtype = torch.float
        args.attn_softmax_bf16 = False

    model_kwargs = {
        "revision": args.model_revision,
        "token": args.token,
    }

    model_name_or_path = args.model_name_or_path
    model = load_model(
        model_name_or_path, model_dtype, model_kwargs, logger, args.use_hpu_graphs
    )
    processor = load_processor(model_name_or_path, logger)

    init_end = time.perf_counter()
    logger.info(f"Args: {args}")
    logger.info(
        f"device: {args.device}, n_hpu: {args.world_size}, dtype: {model_dtype}"
    )
    logger.info(f"Model initialization took {(init_end - init_start):.3f}s")

    return model, processor
