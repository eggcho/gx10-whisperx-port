FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04 AS ctranslate2-builder

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PATH=/root/.pyenv/shims:/root/.pyenv/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apt-get update -qq && apt-get install -qqy --no-install-recommends \
    make \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    libopenblas-dev \
    libomp-dev \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    wget \
    curl \
    llvm \
    libncurses5-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libffi-dev \
    liblzma-dev \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -s -S -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash && \
    git clone https://github.com/momo-lab/pyenv-install-latest.git "$(pyenv root)"/plugins/pyenv-install-latest && \
    pyenv install-latest "3.11" && \
    pyenv global "$(pyenv install-latest --print "3.11")"

WORKDIR /tmp

RUN git clone --recursive --branch v4.3.1 https://github.com/OpenNMT/CTranslate2.git /tmp/ctranslate2-src

WORKDIR /tmp/ctranslate2-src
RUN cmake -S . -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/opt/ctranslate2 \
    -DWITH_CUDA=ON \
    -DWITH_CUDNN=ON \
    -DWITH_MKL=OFF \
    -DCUDA_DYNAMIC_LOADING=ON \
    -DCUDA_ARCH_LIST=Common \
    -DBUILD_CLI=OFF \
    -DOPENMP_RUNTIME=COMP && \
    cmake --build build --parallel && \
    cmake --install build

WORKDIR /tmp/ctranslate2-src/python
RUN pip install --upgrade "pip<25" "setuptools==74.0.0" "wheel==0.42.0" && \
    pip install pybind11 numpy packaging && \
    CTRANSLATE2_ROOT=/opt/ctranslate2 pip wheel . -w /tmp/wheels

FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    LD_LIBRARY_PATH=/opt/ctranslate2/lib:${LD_LIBRARY_PATH} \
    PATH=/root/.pyenv/shims:/root/.pyenv/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apt-get update -qq && apt-get install -qqy --no-install-recommends \
    make \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    wget \
    curl \
    llvm \
    libncurses5-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libffi-dev \
    liblzma-dev \
    git \
    ca-certificates \
    ffmpeg \
    libavformat-dev \
    libavcodec-dev \
    libavdevice-dev \
    libavutil-dev \
    libavfilter-dev \
    libswscale-dev \
    libswresample-dev \
    && rm -rf /var/lib/apt/lists/*

RUN curl -s -S -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash && \
    git clone https://github.com/momo-lab/pyenv-install-latest.git "$(pyenv root)"/plugins/pyenv-install-latest && \
    pyenv install-latest "3.11" && \
    pyenv global "$(pyenv install-latest --print "3.11")"

WORKDIR /src

COPY --from=ctranslate2-builder /opt/ctranslate2 /opt/ctranslate2
COPY --from=ctranslate2-builder /tmp/wheels /tmp/wheels

COPY requirements.txt /tmp/requirements.txt
RUN pip install --upgrade "pip<25" "setuptools==74.0.0" "wheel==0.42.0" && \
    pip install "Cython<3.1" && \
    pip install /tmp/wheels/ctranslate2-*.whl && \
    pip install --no-build-isolation -r /tmp/requirements.txt && \
    pip install cog==0.9.4

COPY src /src
COPY predict.py /src/predict.py

EXPOSE 5000
ENTRYPOINT ["/bin/bash", "-lc"]
CMD ["python -m cog.server.http"]
