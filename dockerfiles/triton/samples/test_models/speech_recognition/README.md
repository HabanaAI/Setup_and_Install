## TRITON SERVER AND CLIENT FOR WHISPER ASR MODELS

### INSTALLATIONS
```
pip install git+https://github.com/huggingface/optimum-habana.git
```
```
export HF_HOME=/data/huggingface_cache
export TRANSFORMERS_CACHE=$HF_HOME/models
export HF_HUB_CACHE=$HF_HOME/hub
export HF_TOKEN="huggingface token"
```

### STARTING THE TRITON SERVER 
```
cd Setup_and_Install/dockerfiles/triton/samples/test_models/speech_recognition
pip install -r requirements.txt
tritonserver --model-repository model_repo --log-verbose=5
```

### RUNNING TRITON ASYNC HTTP CLIENT FOR CONCURRENCY TEST
```
cd Setup_and_Install/dockerfiles/triton/samples/test_models/speech_recognition

python simple_http_client_async.py <num concurrent reqs>  <audio_file>

example : python simple_http_client_async.py 50 "sample_audio/en2.wav"
```

Note : 

Works with batches. Max batch size can be controlled by `max_batch_size: batch_size` field in config.pbtxt.  

Dynamic batching supported.  Refer `dynamic_batching` section in config.

Currently warmup logic is still being tested. Bucketing strategy like vllm-fork might help getting better performance. 

Testing in progress for more Triton server based perf optimisations.
