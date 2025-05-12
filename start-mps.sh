#!/bin/bash

# Get project root directory
PROJECT_ROOT=$(pwd)

# Set environment variables for MPS
export USE_GPU=true
export DEVICE_TYPE=mps # Explicitly set to MPS, though auto-detection should work
export PYTORCH_ENABLE_MPS_FALLBACK=1 # Enable CPU fallback for unsupported MPS ops
export USE_ONNX=false # Assuming ONNX is not used with MPS for now
export PYTHONPATH=$PROJECT_ROOT:$PROJECT_ROOT/api
export MODEL_DIR=src/models
export VOICES_DIR=src/voices/v1_0
export WEB_PLAYER_PATH=$PROJECT_ROOT/web
# Set the espeak-ng data path - this might need adjustment for macOS
# On macOS, espeak-ng data is often found via `brew --prefix espeak-ng`/share/espeak-ng-data
# For now, let's comment it out or ensure espeak-ng is correctly installed and discoverable
# export ESPEAK_DATA_PATH=/opt/homebrew/share/espeak-ng-data # Example for Homebrew on Apple Silicon

# Create a virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
  echo "Creating virtual environment with uv..."
  if ! uv venv; then
    echo "Failed to create virtual environment. Please check your uv and Python setup."
    exit 1
  fi
  echo "Virtual environment created."
fi

echo "Ensuring dependencies are installed for MPS (uses 'cpu' extras for PyTorch)..."
# Installs PyTorch without CUDA, which is what MPS uses.
if ! uv pip install -e ".[cpu]"; then
    echo "Failed to install dependencies. Please check your uv and Python setup."
    exit 1
fi

echo "Downloading models (if necessary)..."
if ! uv run --no-sync python docker/scripts/download_model.py --output api/src/models/v1_0; then
    echo "Failed to download models."
    exit 1
fi

# Apply the misaki patch - comment out if not needed or causing issues
# echo "Applying misaki patch..."
# python scripts/fix_misaki.py

echo "Starting the server with MPS support..."
# Start the server using uvicorn via uv
if ! uv run --no-sync uvicorn api.src.main:app --host 0.0.0.0 --port 8880; then
    echo "Failed to start the server. Please check for errors above."
    exit 1
fi