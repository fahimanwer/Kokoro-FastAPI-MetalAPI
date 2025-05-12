<p align="center">
  <img src="githubbanner.png" alt="Kokoro TTS Banner">
</p>

# <sub><sub>_`FastKoko`_ </sub></sub>
[![Tests](https://img.shields.io/badge/tests-69-darkgreen)]()
[![Coverage](https://img.shields.io/badge/coverage-54%25-tan)]()
[![Try on Spaces](https://img.shields.io/badge/%F0%9F%A4%97%20Try%20on-Spaces-blue)](https://huggingface.co/spaces/Remsky/Kokoro-TTS-Zero)

[![Kokoro](https://img.shields.io/badge/kokoro-0.9.2-BB5420)](https://github.com/hexgrad/kokoro)
[![Misaki](https://img.shields.io/badge/misaki-0.9.3-B8860B)](https://github.com/hexgrad/misaki)

[![Tested at Model Commit](https://img.shields.io/badge/last--tested--model--commit-1.0::9901c2b-blue)](https://huggingface.co/hexgrad/Kokoro-82M/commit/9901c2b79161b6e898b7ea857ae5298f47b8b0d6)

Dockerized FastAPI wrapper for [Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M) text-to-speech model
- Multi-language support (English, Japanese, Korean, Chinese, _Vietnamese soon_)
- OpenAI-compatible Speech endpoint, NVIDIA GPU accelerated or CPU inference with PyTorch 
- Apple Silicon (M1/M2/M3) GPU acceleration via Metal Performance Shaders (MPS)
- ONNX support coming soon, see v0.1.5 and earlier for legacy ONNX support in the interim
- Debug endpoints for monitoring system stats, integrated web UI on localhost:8880/web
- Phoneme-based audio generation, phoneme generation
- Per-word timestamped caption generation
- Voice mixing with weighted combinations

### Integration Guides
 [![Helm Chart](https://img.shields.io/badge/Helm%20Chart-black?style=flat&logo=helm&logoColor=white)](https://github.com/remsky/Kokoro-FastAPI/wiki/Setup-Kubernetes) [![DigitalOcean](https://img.shields.io/badge/DigitalOcean-black?style=flat&logo=digitalocean&logoColor=white)](https://github.com/remsky/Kokoro-FastAPI/wiki/Integrations-DigitalOcean) [![SillyTavern](https://img.shields.io/badge/SillyTavern-black?style=flat&color=red)](https://github.com/remsky/Kokoro-FastAPI/wiki/Integrations-SillyTavern)
[![OpenWebUI](https://img.shields.io/badge/OpenWebUI-black?style=flat&color=white)](https://github.com/remsky/Kokoro-FastAPI/wiki/Integrations-OpenWebUi)
## Get Started

<details>
<summary>Quickest Start (docker run)</summary>


Pre built images are available to run, with arm/multi-arch support, and baked in models
Refer to the core/config.py file for a full list of variables which can be managed via the environment

```bash
# the `latest` tag can be used, though it may have some unexpected bonus features which impact stability.
 Named versions should be pinned for your regular usage.
 Feedback/testing is always welcome

docker run -p 8880:8880 ghcr.io/remsky/kokoro-fastapi-cpu:latest # CPU, or:
docker run --gpus all -p 8880:8880 ghcr.io/remsky/kokoro-fastapi-gpu:latest  #NVIDIA GPU
```


</details>

<details>

<summary>Quick Start (docker compose) </summary>

1. Install prerequisites, and start the service using Docker Compose (Full setup including UI):
   - Install [Docker](https://www.docker.com/products/docker-desktop/)
   - Clone the repository:
        ```bash
        git clone https://github.com/remsky/Kokoro-FastAPI.git
        cd Kokoro-FastAPI

        cd docker/gpu  # For GPU support
        # or cd docker/cpu  # For CPU support
        docker compose up --build

        # *Note for Apple Silicon (M1/M2/M3) users:
        # The Docker GPU build (`docker/gpu`) relies on CUDA and is not compatible with Apple Silicon.
        # For Docker on Apple Silicon, use the `docker/cpu` setup which now automatically detects 
        # and utilizes MPS (Metal Performance Shaders) when running on Apple Silicon.
        # For native Apple Silicon GPU support without Docker, see the "Direct Run (via uv)" 
        # section below for instructions on using the `start-mps.sh` script.

        # Models will auto-download, but if needed you can manually download:
        python docker/scripts/download_model.py --output api/src/models/v1_0

        # Or run directly via UV:
        ./start-gpu.sh  # For GPU support
        ./start-cpu.sh  # For CPU support
        ```
</details>
<details>
<summary>Direct Run (via uv) </summary>

1.  Install prerequisites:
    *   Install [uv](https://docs.astral.sh/uv/) (a fast Python package installer and resolver).
    *   Install `git`.
    *   (Optional but Recommended for some audio formats) Install [ffmpeg](https://ffmpeg.org/download.html).
    *   (macOS) Install `espeak-ng`: `brew install espeak-ng`

2.  Clone the repository:
    ```bash
    git clone https://github.com/remsky/Kokoro-FastAPI.git
    cd Kokoro-FastAPI
    ```

3.  Start the server:
    *   **For NVIDIA GPU (Linux/WSL2):**
        ```bash
        ./start-gpu.sh
        ```
    *   **For CPU:**
        ```bash
        ./start-cpu.sh
        ```
    *   **For Apple Silicon (M1/M2/M3 Macs with MPS):**
        A script `start-mps.sh` is provided to run the application using Apple's Metal Performance Shaders for GPU acceleration.
        ```bash
        ./start-mps.sh
        ```
        This script will:
        *   Create a virtual environment using `uv venv` if one doesn't exist.
        *   Install dependencies using `uv pip install -e ".[cpu]"`. The CPU extras include the base PyTorch version compatible with MPS.
        *   Set necessary environment variables, including `DEVICE_TYPE=mps` and `PYTORCH_ENABLE_MPS_FALLBACK=1`. The fallback is important as some PyTorch operations used by the model may not yet have full MPS support, and this allows them to run on the CPU.
        *   Download models and start the Uvicorn server.

        **Note on `ffmpeg` for MPS users:** The server may log a warning if `ffmpeg` is not found. While not strictly required for basic WAV/MP3 output, installing `ffmpeg` (e.g., `brew install ffmpeg`) is recommended for full audio format support.

4.  (First run) The necessary models will be downloaded automatically. This might take some time.

5.  Once started, you can access:
    *   The API: `http://localhost:8880`
    *   API Documentation: `http://localhost:8880/docs`
    *   Web Interface: `http://localhost:8880/web`

</details>

<details open>
<summary> Up and Running? </summary>


Run locally as an OpenAI-Compatible Speech Endpoint
    
```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8880/v1", api_key="not-needed"
)

with client.audio.speech.with_streaming_response.create(
    model="kokoro",
    voice="af_sky+af_bella", #single or multiple voicepack combo
    input="Hello world!"
  ) as response:
      response.stream_to_file("output.mp3")
```
  
- The API will be available at http://localhost:8880
- API Documentation: http://localhost:8880/docs

- Web Interface: http://localhost:8880/web

<div align="center" style="display: flex; justify-content: center; gap: 10px;">
  <img src="assets/docs-screenshot.png" width="42%" alt="API Documentation" style="border: 2px solid #333; padding: 10px;">
  <img src="assets/webui-screenshot.png" width="42%" alt="Web UI Screenshot" style="border: 2px solid #333; padding: 10px;">
</div>

</details>

## Features 

<details>
<summary>OpenAI-Compatible Speech Endpoint</summary>

```python
# Using OpenAI's Python library
from openai import OpenAI
client = OpenAI(base_url="http://localhost:8880/v1", api_key="not-needed")
response = client.audio.speech.create(
    model="kokoro",  
    voice="af_bella+af_sky", # see /api/src/core/openai_mappings.json to customize
    input="Hello world!",
    response_format="mp3"
)

response.stream_to_file("output.mp3")
```
Or Via Requests:
```python
import requests


response = requests.get("http://localhost:8880/v1/audio/voices")
voices = response.json()["voices"]

# Generate audio
response = requests.post(
    "http://localhost:8880/v1/audio/speech",
    json={
        "model": "kokoro",  
        "input": "Hello world!",
        "voice": "af_bella",
        "response_format": "mp3",  # Supported: mp3, wav, opus, flac
        "speed": 1.0
    }
)

# Save audio
with open("output.mp3", "wb") as f:
    f.write(response.content)
```

Quick tests (run from another terminal):
```bash
python examples/assorted_checks/test_openai/test_openai_tts.py # Test OpenAI Compatibility
python examples/assorted_checks/test_voices/test_all_voices.py # Test all available voices
```
</details>

<details>
<summary>Voice Combination</summary>

- Weighted voice combinations using ratios (e.g., "af_bella(2)+af_heart(1)" for 67%/33% mix)
- Ratios are automatically normalized to sum to 100%
- Available through any endpoint by adding weights in parentheses
- Saves generated voicepacks for future use

Combine voices and generate audio:
```python
import requests
response = requests.get("http://localhost:8880/v1/audio/voices")
voices = response.json()["voices"]

# Example 1: Simple voice combination (50%/50% mix)
response = requests.post(
    "http://localhost:8880/v1/audio/speech",
    json={
        "input": "Hello world!",
        "voice": "af_bella+af_sky",  # Equal weights
        "response_format": "mp3"
    }
)

# Example 2: Weighted voice combination (67%/33% mix)
response = requests.post(
    "http://localhost:8880/v1/audio/speech",
    json={
        "input": "Hello world!",
        "voice": "af_bella(2)+af_sky(1)",  # 2:1 ratio = 67%/33%
        "response_format": "mp3"
    }
)

# Example 3: Download combined voice as .pt file
response = requests.post(
    "http://localhost:8880/v1/audio/voices/combine",
    json="af_bella(2)+af_sky(1)"  # 2:1 ratio = 67%/33%
)

# Save the .pt file
with open("combined_voice.pt", "wb") as f:
    f.write(response.content)

# Use the downloaded voice file
response = requests.post(
    "http://localhost:8880/v1/audio/speech",
    json={
        "input": "Hello world!",
        "voice": "combined_voice",  # Use the saved voice file
        "response_format": "mp3"
    }
)

```
<p align="center">
  <img src="assets/voice_analysis.png" width="80%" alt="Voice Analysis Comparison" style="border: 2px solid #333; padding: 10px;">
</p>
</details>

<details>
<summary>Multiple Output Audio Formats</summary>

- mp3
- wav
- opus 
- flac
- m4a
- pcm

<p align="center">
<img src="assets/format_comparison.png" width="80%" alt="Audio Format Comparison" style="border: 2px solid #333; padding: 10px;">
</p>

</details>

<details>
<summary>Streaming Support</summary>

```python
# OpenAI-compatible streaming
from openai import OpenAI
client = OpenAI(
    base_url="http://localhost:8880/v1", api_key="not-needed")

# Stream to file
with client.audio.speech.with_streaming_response.create(
    model="kokoro",
    voice="af_bella",
    input="Hello world!"
) as response:
    response.stream_to_file("output.mp3")

# Stream to speakers (requires PyAudio)
import pyaudio
player = pyaudio.PyAudio().open(
    format=pyaudio.paInt16, 
    channels=1, 
    rate=24000, 
    output=True
)

with client.audio.speech.with_streaming_response.create(
    model="kokoro",
    voice="af_bella",
    response_format="pcm",
    input="Hello world!"
) as response:
    for chunk in response.iter_bytes(chunk_size=1024):
        player.write(chunk)
```

Or via requests:
```python
import requests

response = requests.post(
    "http://localhost:8880/v1/audio/speech",
    json={
        "input": "Hello world!",
        "voice": "af_bella",
        "response_format": "pcm"
    },
    stream=True
)

for chunk in response.iter_content(chunk_size=1024):
    if chunk:
        # Process streaming chunks
        pass
```

<p align="center">
  <img src="assets/gpu_first_token_timeline_openai.png" width="45%" alt="GPU First Token Timeline" style="border: 2px solid #333; padding: 10px; margin-right: 1%;">
  <img src="assets/cpu_first_token_timeline_stream_openai.png" width="45%" alt="CPU First Token Timeline" style="border: 2px solid #333; padding: 10px;">
</p>

Key Streaming Metrics:
- First token latency @ chunksize
    - ~300ms  (GPU) @ 400 
    - ~3500ms (CPU) @ 200 (older i7)
    - ~<1s    (CPU) @ 200 (M3 Pro)
    - ~<1s    (MPS) @ 200 (M1/M2/M3)
- Adjustable chunking settings for real-time playback 

*Note: Artifacts in intonation can increase with smaller chunks*
</details>

## Processing Details
<details>
<summary>Performance Benchmarks</summary>

Benchmarking was performed on generation via the local API using text lengths up to feature-length books (~1.5 hours output), measuring processing time and realtime factor. Tests were run on: 
- Windows 11 Home w/ WSL2 
- NVIDIA 4060Ti 16gb GPU @ CUDA 12.1
- 11th Gen i7-11700 @ 2.5GHz
- 64gb RAM
- WAV native output
- H.G. Wells - The Time Machine (full text)

<p align="center">
  <img src="assets/gpu_processing_time.png" width="45%" alt="Processing Time" style="border: 2px solid #333; padding: 10px; margin-right: 1%;">
  <img src="assets/gpu_realtime_factor.png" width="45%" alt="Realtime Factor" style="border: 2px solid #333; padding: 10px;">
</p>

Key Performance Metrics:
- Realtime Speed: Ranges between 35x-100x (generation time to output audio length)
- Average Processing Rate: 137.67 tokens/second (cl100k_base)
</details>
<details>
<summary>GPU Vs. CPU Vs. MPS</summary>

```bash
# NVIDIA GPU: Requires NVIDIA GPU with CUDA 12.8 support (~35x-100x realtime speed)
cd docker/gpu
docker compose up --build

# CPU: PyTorch CPU inference
cd docker/cpu
docker compose up --build

# Apple Silicon MPS: Direct run (not Docker)
./start-mps.sh
```

*Note: The Apple Silicon (M1/M2/M3) setup via MPS generally provides 3-5x faster inference than CPU mode, though performance varies by model.*

*Note: When running the CPU Docker container on Apple Silicon, it will now automatically detect and use MPS if available, with CPU fallback for unsupported operations.*

*Note: Overall speed may have reduced somewhat with the structural changes to accommodate streaming. Looking into it* 
</details>

<details>
<summary>Natural Boundary Detection</summary>

- Automatically splits and stitches at sentence boundaries 
- Helps to reduce artifacts and allow long form processing as the base model is only currently configured for approximately 30s output

The model is capable of processing up to a 510 phonemized token chunk at a time, however, this can often lead to 'rushed' speech or other artifacts. An additional layer of chunking is applied in the server, that creates flexible chunks with a `TARGET_MIN_TOKENS` , `TARGET_MAX_TOKENS`, and `ABSOLUTE_MAX_TOKENS` which are configurable via environment variables, and set to 175, 250, 450 by default

</details>

<details>
<summary>Timestamped Captions & Phonemes</summary>

Provides text to speech broken into the three chunks for troubleshooting and verification, as well as enabling caption generation with timestamps for each word.

```python
import requests

response = requests.post(
    "http://localhost:8880/v1/audio/generate/all",
    json={
        "text": "Hello world!",
        "voice": "af_bella",
    }
)

result = response.json()
print(result["phonemes"]) # Show the phoneme prediction of the model
print(result["timestamps"]) # Show the per-word timestamps
```

```sh
{ 
    "phonemes": "HH AH0 L OW1 . W ER1 L D .",
    "timestamps": [
        { "word": "Hello", "time": 103 },
        { "word": "world!", "time": 400 }
    ]
}

```

**Phoneme Debugging** is also available via the `/v1/audio/generate/phonemes` endpoint.

*Note: More elaborate timestamping options may be implemented in the future* 
</details>

<details>
<summary>MPS Support for Apple Silicon</summary>

This project now includes full support for Apple Silicon (M1/M2/M3) GPUs using Metal Performance Shaders (MPS). This provides significantly better performance than CPU-only mode.

### Key Features:
- **Auto-detection:** When using Docker, the CPU image will automatically detect Apple Silicon and use MPS if available.
- **CPU Fallback:** Uses `PYTORCH_ENABLE_MPS_FALLBACK=1` to handle operations not supported by MPS.
- **Native Script:** A dedicated `start-mps.sh` script for non-Docker setup.

### Docker Performance Notes:
- When running on an Apple Silicon Mac with Docker Desktop, make sure Docker is properly configured to use the host's GPU.
- The Docker CPU image automatically detects and uses MPS on Apple Silicon.

### Native Setup (recommended for best performance):
1. Run the dedicated script:
```bash
./start-mps.sh
```

This script:
- Sets the appropriate environment variables
- Installs dependencies compatible with MPS
- Enables CPU fallback for operations not supported by MPS

### Troubleshooting:
- If you encounter warnings about "operator 'aten::angle' not implemented for MPS", this is normal and will be handled by the CPU fallback.
- For optimal performance on Apple Silicon, ensure you have ffmpeg installed via homebrew: `brew install ffmpeg`.
</details>

## Model and License

<details open>
<summary>Model</summary>

This API uses the [Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M) model from HuggingFace. 

Visit the model page for more details about training, architecture, and capabilities. I have no affiliation with any of their work, and produced this wrapper for ease of use and personal projects.
</details>
<details>
<summary>License</summary>
This project is licensed under the Apache License 2.0 - see below for details:

- The Kokoro model weights are licensed under Apache 2.0 (see [model page](https://huggingface.co/hexgrad/Kokoro-82M))
- The FastAPI wrapper code in this repository is licensed under Apache 2.0 to match
- The inference code adapted from StyleTTS2 is MIT licensed

The full Apache 2.0 license text can be found at: https://www.apache.org/licenses/LICENSE-2.0
</details>