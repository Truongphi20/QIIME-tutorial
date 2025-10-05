FROM mambaorg/micromamba:1.5.8

WORKDIR /workspace

# Install system tools: git + bash-completion
USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        bash-completion \
        openssh-client \
        less \
    && rm -rf /var/lib/apt/lists/*

# Copy environment.yml into image
COPY environment.yml /tmp/environment.yml

# Install environment (Nextflow, Java, bio tools, etc.)
RUN micromamba create -y -f /tmp/environment.yml -n nf-env && \
    micromamba clean --all --yes

# Auto-activate micromamba env
ENV MAMBA_DOCKERFILE_ACTIVATE=1
SHELL ["/bin/bash", "-c"]

# Enable bash completion globally
RUN echo "if [ -f /etc/bash_completion ]; then . /etc/bash_completion; fi" >> /etc/bash.bashrc

# Add vscode user
RUN useradd -ms /bin/bash vscode
USER vscode

# Activate conda env
RUN echo 'eval "$(micromamba shell hook --shell=bash)"' >> /home/vscode/.bashrc && \
    echo 'micromamba activate nf-env' >> /home/vscode/.bashrc
