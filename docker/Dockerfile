ARG PYTHON_VERSION="3.13"

FROM python:${PYTHON_VERSION}-slim-bookworm AS base
ARG DEBIAN_FRONTEND="noninteractive"

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONIOENCODING=utf8 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

FROM base AS builder
ARG DEBIAN_FRONTEND="noninteractive"

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential && \
    rm -rf /var/lib/apt/lists/*

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:${PATH}"

COPY prod-requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r prod-requirements.txt

FROM base AS runtime

ARG NON_ROOT_USER="template"
ARG NON_ROOT_UID="2222"
ARG NON_ROOT_GID="2222"
ARG HOME_DIR="/home/${NON_ROOT_USER}"
ARG REPO_DIR="."

RUN groupadd -g ${NON_ROOT_GID} ${NON_ROOT_USER} && \
    useradd -l -m -s /bin/bash -u ${NON_ROOT_UID} -g ${NON_ROOT_GID} ${NON_ROOT_USER}

COPY --from=builder /opt/venv /opt/venv

ENV PATH="/opt/venv/bin:${HOME_DIR}/.local/bin:${PATH}"
ENV PYTHONPATH="${HOME_DIR}"

USER ${NON_ROOT_USER}
WORKDIR ${HOME_DIR}

COPY --chown=${NON_ROOT_USER}:${NON_ROOT_GID} ${REPO_DIR} .

ENTRYPOINT ["python3"]
