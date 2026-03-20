FROM python:3.12.10-slim

ARG DEBIAN_FRONTEND="noninteractive"

ARG NON_ROOT_USER="template"
ARG NON_ROOT_UID="2222"
ARG NON_ROOT_GID="2222"
ARG HOME_DIR="/home/${NON_ROOT_USER}"
ARG REPO_DIR="."

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -l -m -s /bin/bash -u ${NON_ROOT_UID} ${NON_ROOT_USER}

ENV PYTHONIOENCODING=utf8
ENV LANG="C.UTF-8"
ENV LC_ALL="C.UTF-8"
ENV PATH="/home/template/.local/bin:${PATH}"
ENV PYTHONPATH="${HOME_DIR}:${PYTHONPATH}"

USER ${NON_ROOT_USER}
WORKDIR ${HOME_DIR}/${REPO_DIR}

# Copy only the requirements file first to leverage Docker cache
COPY --chown=${NON_ROOT_USER}:${NON_ROOT_GID} ${REPO_DIR}/prod-requirements.txt ./prod-requirements.txt

# Install pip requirements
RUN pip install --no-cache-dir -r prod-requirements.txt

# Copy the rest of the application code
COPY --chown=${NON_ROOT_USER}:${NON_ROOT_GID} ${REPO_DIR} .

ENTRYPOINT ["python3"]
