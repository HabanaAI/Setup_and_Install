import json
import logging
import os
from time import time

import numpy as np

# triton_python_backend_utils is available in every Triton Python model. You
# need to use this module to create inference requests and responses. It also
# contains some utility functions for extracting information from model_config
# and converting Triton input/output types to numpy types.
import triton_python_backend_utils as pb_utils
from utils import count_hpu_graphs, initialize_model_n_processor, read_audio

gen_kwargs = {}


class habana_args:
    device = "hpu"
    model_name_or_path = "openai/whisper-large-v2"
    audio_file = "en1.wav"
    token = None
    bf16 = True
    use_hpu_graphs = True
    seed = 42
    batch_size = -1
    model_revision = "main"
    sampling_rate = 16000
    global_rank = 0
    world_size = 1
    local_rank = 0


logging.basicConfig(
    format="%(asctime)s - %(levelname)s - %(name)s - %(message)s",
    datefmt="%m/%d/%Y %H:%M:%S",
    level=logging.INFO,
)
logger = logging.getLogger(__name__)


class TritonPythonModel:
    """Your Python model must use the same class name. Every Python model
    that is created must have "TritonPythonModel" as the class name.
    """

    def initialize(self, args):
        """`initialize` is called only once when the model is being loaded.
        Implementing `initialize` function is optional. This function allows
        the model to initialize any state associated with this model.

        Parameters
        ----------
        args : dict
          Both keys and values are strings. The dictionary keys and values are:
          * model_config: A JSON string containing the model configuration
          * model_instance_kind: A string containing model instance kind
          * model_instance_device_id: A string containing model instance device ID
          * model_repository: Model repository path
          * model_version: Model version
          * model_name: Model name
        """
        print(f"Initializing")
        self.model, self.processor = initialize_model_n_processor(habana_args, logger)
        self.device = self.model.device
        self.model_dtype = self.model.dtype
        self.sampling_rate = habana_args.sampling_rate

        # TEST A SAMPLE DURING INITIALISATION
        cur_dir = os.path.dirname(os.path.abspath(__file__))
        input_speech_arr, sampling_rate = read_audio(
            os.path.join(cur_dir, habana_args.audio_file)
        )
        for i in range(1):
            t1 = time()
            out_transcript = self.infer_transcript(
                input_speech_arr, habana_args.sampling_rate
            )
            t2 = time()
            print(f"Test inference time:{t2-t1}secs  {out_transcript}")

        print("Initialize finished")
        self.model_config = model_config = json.loads(args["model_config"])

        # Get OUTPUT0 configuration
        output0_config = pb_utils.get_output_config_by_name(model_config, "OUTPUT0")

        # Convert Triton types to numpy types
        self.output0_dtype = pb_utils.triton_string_to_numpy(
            output0_config["data_type"]
        )

    def infer_transcript(self, audio_batch, sampling_rate=16000):
        t1 = time()
        input_features = self.processor(
            audio_batch, sampling_rate=sampling_rate, return_tensors="pt"
        ).input_features.to(self.device)
        predicted_ids = self.model.generate(
            input_features.to(self.model_dtype), **gen_kwargs
        )
        transcription = self.processor.batch_decode(
            predicted_ids, skip_special_tokens=True
        )
        t2 = time()
        print(f"Time for {len(transcription)} samples : {t2-t1}secs")
        return transcription

    def batched_inference(self, requests):
        request_batch = []
        for request in requests:
            in_0 = pb_utils.get_input_tensor_by_name(request, "INPUT0")
            request_batch.append(in_0.as_numpy())

        request_batch = np.array(request_batch).squeeze()
        print(
            f"xxxxxxxxxxx AUDIO BATCHED INPUT SIZE : {request_batch.shape} INPUT TYPE : {type(request_batch)}"
        )

        out_0 = self.infer_transcript(request_batch, habana_args.sampling_rate)

        return out_0

    # def execute(self, requests):
    def execute(self, requests):
        """`execute` MUST be implemented in every Python model. `execute`
        function receives a list of pb_utils.InferenceRequest as the only
        argument. This function is called when an inference request is made
        for this model. Depending on the batching configuration (e.g. Dynamic
        Batching) used, `requests` may contain multiple requests. Every
        Python model, must create one pb_utils.InferenceResponse for every
        pb_utils.InferenceRequest in `requests`. If there is an error, you can
        set the error argument when creating a pb_utils.InferenceResponse

        Parameters
        ----------
        requests : list
          A list of pb_utils.InferenceRequest

        Returns
        -------
        list
          A list of pb_utils.InferenceResponse. The length of this list must
          be the same as `requests`
        """

        responses = []

        print(f"NUM REQUESTS {len(requests)}")

        if (
            len(requests) > 1
        ):  # More than 1 requests are received , batch them and infer at once
            out_0_batched = self.batched_inference(requests)
            responses = []
            for i in range(len(requests)):
                # Create OUTPUT tensors
                out_tensor_0 = pb_utils.Tensor(
                    "OUTPUT0", np.array(out_0_batched[i], dtype=self.output0_dtype)
                )
                inference_response = pb_utils.InferenceResponse(
                    output_tensors=[out_tensor_0]
                )
                responses.append(inference_response)
        else:  # Single sample inference
            # Every Python backend must iterate over everyone of the requests and create a pb_utils.InferenceResponse for each of them.
            for request in requests:
                # Get INPUTS
                in_0 = pb_utils.get_input_tensor_by_name(request, "INPUT0")
                input_speech_arr = in_0.as_numpy()
                print(
                    f"xxxxxxxxxxx AUDIO INPUT SIZE : {input_speech_arr.shape} INPUT TYPE : {type(input_speech_arr)}"
                )

                out_0 = self.infer_transcript(
                    input_speech_arr, habana_args.sampling_rate
                )

                # Create OUTPUT tensors. You need pb_utils.Tensor objects to create pb_utils.InferenceResponse.
                out_tensor_0 = pb_utils.Tensor(
                    "OUTPUT0", np.array(out_0, dtype=self.output0_dtype)
                )

                # Create InferenceResponse.
                # pb_utils.InferenceResponse(output_tensors=..., TritonError("An error occurred"))
                inference_response = pb_utils.InferenceResponse(
                    output_tensors=[out_tensor_0]
                )
                responses.append(inference_response)

        # You should return a list of pb_utils.InferenceResponse. Length of this list must match the length of `requests` list.
        return responses

    def finalize(self):
        """`finalize` is called only once when the model is being unloaded.
        Implementing `finalize` function is OPTIONAL. This function allows
        the model to perform any necessary clean ups before exit.
        """
        print("Cleaning up...")
