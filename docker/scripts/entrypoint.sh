#!/bin/bash
set -e

# --- BEGIN MPS Detection Logic ---
DEFAULT_UV_EXTRA="cpu" 
APP_DEVICE_TYPE="cpu"
APP_USE_GPU="false"
PYTORCH_AVAILABLE=false

# First, check if PyTorch is even importable
if python -c "import torch" &> /dev/null; then
    PYTORCH_AVAILABLE=true
    echo "PyTorch is importable."
else
    echo "Error: PyTorch is not importable. Cannot check for MPS. Defaulting to CPU."
fi

DETECTED_MPS_STATUS="pytorch_unavailable" 

if [ "$PYTORCH_AVAILABLE" = true ]; then
    # Create a temporary Python script to check for MPS
    cat << EOF > /app/check_mps.py
import torch
import os
import platform

is_arm = platform.machine() in ['arm64', 'aarch64']

if not is_arm:
    print("not_arm_architecture")
elif hasattr(torch.backends, 'mps') and torch.backends.mps.is_available():
    print("mps_available")
else:
    print("mps_unavailable_in_pytorch_or_environment")
EOF

    SCRIPT_OUTPUT=$(python /app/check_mps.py 2>&1)
    SCRIPT_EXIT_CODE=$?
    rm /app/check_mps.py 

    if [ $SCRIPT_EXIT_CODE -eq 0 ]; then
        DETECTED_MPS_STATUS="$SCRIPT_OUTPUT"
    else
        echo "Error running MPS detection script. Exit code: $SCRIPT_EXIT_CODE"
        echo "Script output/error: $SCRIPT_OUTPUT"
        DETECTED_MPS_STATUS="detection_script_failed"
    fi
fi

# Normalize DETECTED_MPS_STATUS by removing potential newlines from script output
DETECTED_MPS_STATUS=$(echo "$DETECTED_MPS_STATUS" | tr -d '\n')

echo "MPS Detection Status: $DETECTED_MPS_STATUS"

if [ "$DETECTED_MPS_STATUS" = "mps_available" ]; then
    echo "MPS device detected and accessible. Configuring for MPS."
    DEFAULT_UV_EXTRA="cpu" 
    APP_DEVICE_TYPE="mps"
    APP_USE_GPU="true"
    export PYTORCH_ENABLE_MPS_FALLBACK=1
    echo "PYTORCH_ENABLE_MPS_FALLBACK enabled."
else
    echo "MPS not configured (Reason/Status: $DETECTED_MPS_STATUS). Defaulting to CPU."
fi

export USE_GPU=${APP_USE_GPU}
export DEVICE_TYPE=${APP_DEVICE_TYPE}

echo "Final app config: USE_GPU=${USE_GPU}, DEVICE_TYPE=${DEVICE_TYPE}"
echo "Using uv run --extra ${DEFAULT_UV_EXTRA}"
# --- END MPS Detection Logic ---

if [ "$DOWNLOAD_MODEL" = "true" ]; then
    echo "Downloading model..."
    python download_model.py --output api/src/models/v1_0
fi

echo "Starting Uvicorn server..."
exec uv run --extra $DEFAULT_UV_EXTRA --no-sync python -m uvicorn api.src.main:app --host 0.0.0.0 --port 8880 --log-level debug