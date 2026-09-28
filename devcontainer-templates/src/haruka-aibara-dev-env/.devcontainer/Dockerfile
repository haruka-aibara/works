# Base image: mcr.microsoft.com/devcontainers/base:ubuntu-24.04 (LTS), pinned by digest for reproducibility.
# We pin to the 24.04 LTS line rather than the rolling ':ubuntu' tag, which now points to a
# non-LTS interim release ('resolute') that lacks moby packages and breaks docker-in-docker.
# Digest-only (no tag) form is required: the devcontainer CLI cannot parse a combined name:tag@sha256 reference.
# Renovate が ubuntu-24.04 タグの digest を追跡・更新する（renovate.json の customManagers）。
# renovate: datasource=docker depName=mcr.microsoft.com/devcontainers/base tag=ubuntu-24.04
ARG BASE_IMAGE=mcr.microsoft.com/devcontainers/base@sha256:d94c97dd9cacf183d0a6fd12a8e87b526e9e928307674ae9c94139139c0c6eae

FROM ${BASE_IMAGE}
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# tenv (Terraform/OpenTofu version manager) and uv (Python package/env manager) are copied
# from their official multi-arch images, pinned by tag + digest. Renovate's dockerfile manager
# tracks both, so no per-arch SHA256 needs to be maintained here.
COPY --from=ghcr.io/tofuutils/tenv:4.15.1@sha256:1132db268644e2768beb7ffe60fb2688bd33f4bab85ec105b2812bea0ad44cfb /usr/local/bin/tenv /usr/bin/tenv
COPY --from=ghcr.io/astral-sh/uv:0.12.19@sha256:04d046b13e60d6bcec73cbc5e1cad25d680dea90c8573340950a0ac2d1aef424 /uv /uvx /usr/local/bin/

# Installing minimal set of essential system tools for development
# Grouped in a single RUN command to reduce image layers
# hadolint ignore=DL3008
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y --no-install-recommends \
        unzip \
        zip \
        gzip \
        tar \
        curl \
        wget \
        htop \
        tree \
        jq \
        ca-certificates \
    # Adding Google Cloud SDK repository for gcloud CLI installation (official apt repo, keyring-verified)
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-cloud-cli \
    # Cleaning up to minimize image size
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Setting up a non-root user environment with appropriate permissions
# Creating log directory with restricted permissions for security
RUN mkdir -p /home/vscode/logs \
    && chown -R vscode:vscode /home/vscode \
    && chmod -R 750 /home/vscode

# Creating application log directory with proper permissions
# Ensuring logs are writable by the application user but protected from others
RUN mkdir -p /var/log/app \
    && chown vscode:vscode /var/log/app \
    && chmod 750 /var/log/app

# Switching to non-root user for better security
# Running as root in containers is a security risk
USER vscode

# Setting the working directory for all subsequent operations
WORKDIR /home/vscode

# Installing Claude Code CLI from a pinned version with checksum verification.
# We bypass install.sh (which always pulls latest) to pin the version for reproducibility.
# Checksums match the claude binary in the official npm platform packages (@anthropic-ai/claude-code-linux-*).
# Renovate bumps the version; .github/workflows/devcontainer-checksums.yaml then rewrites the SHA256s.
# renovate: datasource=npm depName=@anthropic-ai/claude-code
ARG CLAUDE_VERSION=2.1.282
ARG CLAUDE_SHA256_AMD64=3afe8535c0cc33f0e24f7b25dab7a1727b8b592196f8496a8bc302ba2161eed3
ARG CLAUDE_SHA256_ARM64=6764ffc39e9fed425a493ff61ea28506d1ba83996ce81a48d1177dbb393419c9
ARG TARGETARCH
RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) platform=linux-x64; sha="${CLAUDE_SHA256_AMD64}";; \
      arm64) platform=linux-arm64; sha="${CLAUDE_SHA256_ARM64}";; \
      *) echo "unsupported arch: ${TARGETARCH}"; exit 1;; \
    esac; \
    mkdir -p "$HOME/.local/bin"; \
    curl -fsSL -o claude "https://downloads.claude.ai/claude-code-releases/${CLAUDE_VERSION}/${platform}/claude"; \
    echo "${sha}  claude" | sha256sum -c -; \
    install claude "$HOME/.local/bin/claude"; \
    rm claude

# Adding the user's local bin directory to PATH for installed tools
ENV PATH=/home/vscode/.local/bin:$PATH

# Disable gcloud logging to avoid read-only file system warnings
# ENV CLOUDSDK_CORE_DISABLE_FILE_LOGGING=1

# Adding metadata for better container documentation and transparency
# Includes description, licensing, and source repository information
LABEL org.opencontainers.image.description="Secure development environment for AWS, Terraform, and Python projects"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.source="https://github.com/haruka-aibara/works"
