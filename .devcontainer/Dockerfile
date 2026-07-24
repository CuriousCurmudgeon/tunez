FROM mcr.microsoft.com/devcontainers/base:bookworm

# Build dependencies for compiling Erlang/OTP from source (via asdf/kerl),
# unzip for the asdf elixir plugin, and inotify-tools for Phoenix live reload.
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y --no-install-recommends \
        autoconf \
        build-essential \
        fop \
        inotify-tools \
        libgl1-mesa-dev \
        libglu1-mesa-dev \
        libncurses-dev \
        libpng-dev \
        libssh-dev \
        libssl-dev \
        libwxgtk-webview3.2-dev \
        libwxgtk3.2-dev \
        locales \
        m4 \
        unixodbc-dev \
        unzip \
        xsltproc \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Elixir expects a UTF-8 locale; without it the BEAM warns and can mishandle strings.
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Login shells (e.g. dev container terminals) source /etc/profile, which resets
# PATH and drops the ENV PATH below. Re-add the asdf shims for those shells.
RUN printf 'export ASDF_DATA_DIR=/home/vscode/.asdf\nexport PATH="/home/vscode/.local/bin:$ASDF_DATA_DIR/shims:$PATH"\n' \
        > /etc/profile.d/asdf.sh

USER vscode

# Install the latest (Go-based) asdf release so it reads .tool-versions.
ENV ASDF_DATA_DIR=/home/vscode/.asdf
ENV PATH="/home/vscode/.local/bin:/home/vscode/.asdf/shims:${PATH}"
RUN mkdir -p "$HOME/.local/bin" \
    && ASDF_VERSION="$(curl -fsSL https://api.github.com/repos/asdf-vm/asdf/releases/latest | grep -oP '"tag_name":\s*"\K[^"]+')" \
    && curl -fsSL "https://github.com/asdf-vm/asdf/releases/download/${ASDF_VERSION}/asdf-${ASDF_VERSION}-linux-arm64.tar.gz" \
        | tar -xz -C "$HOME/.local/bin" asdf

# Pre-install the Erlang/Elixir versions pinned in .tool-versions so they are
# baked into an image layer and cached across container rebuilds.
COPY --chown=vscode:vscode .tool-versions /tmp/tunez/.tool-versions
WORKDIR /tmp/tunez
RUN asdf plugin add erlang \
    && asdf plugin add elixir \
    && asdf install \
    && asdf reshim

# Install Hex and Rebar into the pinned Elixir toolchain.
RUN mix local.hex --force && mix local.rebar --force
