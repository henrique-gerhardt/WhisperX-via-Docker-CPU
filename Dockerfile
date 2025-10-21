FROM python:3.10-slim

RUN pip install --upgrade pip setuptools

RUN apt-get update && apt-get install -y \
    git \
    ffmpeg \
    libsndfile1 \
    libgomp1 \
    libjpeg-dev \
    libpng-dev \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install -q git+https://github.com/m-bain/whisperx.git -q

RUN pip3 install -U huggingface_hub

ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/aarch64-linux-gnu/

# Environment variables 
ENV TORCH_HOME=${TORCH_HOME}
ENV HF_HOME=${HF_HOME}
ENV WHISPER_MODEL=${WHISPER_MODEL}
ENV AUDIO_LANG=${AUDIO_LANG}
ENV AUDIO=${AUDIO}

WORKDIR /app

STOPSIGNAL SIGINT
