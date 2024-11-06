import asyncio
import os
import sys
import time

import numpy as np
import soundfile
import tritonclient.http.aio as httpclient
from aiohttp import ClientSession, ClientTimeout
from PIL import Image
from tritonclient.utils import *

http_port = 8000
model_name = "whisper_large_v2"
timeout = 10000  # aiohttp.ClientTimeout(total=600)


def read_audio(audio_file_path):
    audio_array, sample_rate = soundfile.read(audio_file_path)
    return audio_array, sample_rate


def create_random_audio_arr(duration_sec=30, sampling_rate=16000):
    total_samples = duration_sec * sampling_rate
    audio_array = np.random.rand(total_samples)
    return audio_array, sampling_rate


async def infer_http_async(audio_file):
    async with httpclient.InferenceServerClient(
        url=f"localhost:{http_port}", conn_timeout=timeout
    ) as client:
        audio_arr, sampling_rate = read_audio(audio_file)
        # audio_arr, sampling_rate = create_random_audio_arr(duration_sec=12, sampling_rate=16000)
        audio_arr = audio_arr.astype("float32").reshape(1, -1)
        audio_arr = (audio_arr - audio_arr.min()) / (audio_arr.max() - audio_arr.min())

        ## INPUT_0
        input_audio_arr = httpclient.InferInput(
            "INPUT0", audio_arr.shape, np_to_triton_dtype(audio_arr.dtype)
        )
        input_audio_arr.set_data_from_numpy(audio_arr)

        ## OUTPUT
        output_text = httpclient.InferRequestedOutput("OUTPUT0")

        query_response = await client.infer(
            model_name=model_name, inputs=[input_audio_arr], outputs=[output_text]
        )

        print(query_response.as_numpy("OUTPUT0"))


async def infer_http_concurrent(audio_file, num_concurrent_reqs=1):
    print(f"\n\n ============= Running {audio_file}  {num_concurrent_reqs} times ...")
    tasks = []
    for i in range(num_concurrent_reqs):
        print(f"Run {i+1}")
        tasks.append(infer_http_async(audio_file))
    start = time.time()
    await asyncio.gather(*tasks)
    end = time.time()
    print(f"Time taken: {end - start} secs\n")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python async_http_client.py <num_concurrent_reqs> <audio_path>")
        sys.exit(1)

    num_concurrent_reqs = int(sys.argv[1])
    audio_file = sys.argv[2]  # "sample_audio/en2.wav"

    t1 = time.time()
    asyncio.run(infer_http_concurrent(audio_file, num_concurrent_reqs))
    print(f"Total time taken by {os.getpid()}: {time.time() - t1} secs \n")
