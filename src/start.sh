#!/usr/bin/env bash

# Use libtcmalloc for better memory management
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

# ----------------------------------------------------------------------------------------------------
# Run on my local machine (useful during interactive setup). DO NOT push this to Runpod
# Build the base image with this enabled and the runpod version commented out.
# Then when you're ready to push to runpod, comment this out and uncomment the runpod section, docker cp this updated file to the container, then docker commit to create the new image
# --cpu means we use CPU not GPU (because I don't have access to a GPU on this machine); --listen ensures 127.0.0.1:8188 is available outside the docker container
echo "runpod-worker-comfy: Starting ComfyUI"
python3 /comfyui/main.py --disable-auto-launch --disable-metadata --cpu --listen

# ----------------------------------------------------------------------------------------------------
# GPU enhanced version (Runpod version)
#echo "runpod-worker-comfy: Starting ComfyUI"
#python3 /comfyui/main.py --disable-auto-launch --disable-metadata &

#echo "runpod-worker-comfy: Starting RunPod Handler"
#python3 -u /rp_handler.py