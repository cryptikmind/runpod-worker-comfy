# Use Nvidia CUDA base image
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04 as base

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
# Prefer binary wheels over source distributions for faster pip installations
ENV PIP_PREFER_BINARY=1
# Ensures output from python is printed immediately to the terminal without buffering
ENV PYTHONUNBUFFERED=1 

# Install Python, git and other necessary tools
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    wget

# Clean up to reduce image size
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Clone ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui

# Change working directory to ComfyUI
WORKDIR /comfyui

# Install ComfyUI dependencies
RUN pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 \
    && pip3 install --no-cache-dir xformers==0.0.21 \
    && pip3 install -r requirements.txt

# Install runpod
RUN pip3 install runpod requests

# Download checkpoints/vae/LoRA to include in image
#RUN wget -O models/checkpoints/sd_xl_base_1.0.safetensors https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors
#RUN wget -O models/vae/sdxl_vae.safetensors https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors
#RUN wget -O models/vae/sdxl-vae-fp16-fix.safetensors https://huggingface.co/madebyollin/sdxl-vae-fp16-fix/resolve/main/sdxl_vae.safetensors
#RUN wget -O models/loras/xl_more_art-full_v1.safetensors https://civitai.com/api/download/models/152309

# Example for adding specific models into image
# ADD models/checkpoints/sd_xl_base_1.0.safetensors models/checkpoints/
# ADD models/vae/sdxl_vae.safetensors models/vae/

ADD models/sdXL_v10VAEFix.safetensors models/checkpoints/
ADD models/MJBoy1-ohwx-000008.safetensors models/loras/
ADD models/MJGirl4-ohwx-000001.safetensors models/loras/
ADD models/control-lora-canny-rank256.safetensors models/controlnet/control-lora-canny-rank256.safetensors

# ADD custom nodes directory
# . Turns out this doesn't work. We're going to build the image, install the Node Manager, do install it interactively, the commit that for the final image
#ADD models/custom_nodes/comfyui_controlnet_aux custom_nodes/comfyui_controlnet_aux
#WORKDIR /comfyui/custom_nodes/comfyui_controlnet_aux
# Install Python dependencies from requirements.txt
#RUN pip3 install -r requirements.txt

# Install ComfyUI-Manager
WORKDIR /comfyui/custom_nodes
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git

# Go back to the root
WORKDIR /

# Add the start and the handler
ADD src/start.sh src/rp_handler.py test_input.json ./
RUN chmod +x /start.sh

# Start the container
CMD /start.sh

# How to interactively setup Comfy
# . You might need to edit start.sh to start comfy with --cpu and remove the trailing & and following rp_handler.py command
#   (when I don't do this the container doesn't remain running)
# . Start the container: sudo docker run -d -p 8188:8188 --name comfyui_container cryptikmind/runpod-worker-comfy:dev
# . Run Comfy via Firefox, load a workflow with a missing node, Open ComfyManager > Install Missing Nodes
# . Shut down the container and commit. This then becomes the final image that you go with.
# . Of course you could then DIFF the files and just include those in this Docker file (so you don't need to do this interactive step) OR
#   Actually figure out how to install all the nodes you need via git / python commands and include those directly in the Docker file above.
#   But as it stands, since I'm not 100% sure about which nodes and model I'll need, this interactive setup is actually good because it lets me easily run workflows, update the container / image, then push the latest image to Dockerhub / Runpod