FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    sudo curl ca-certificates git fish neovim \
    build-essential cmake make \
    python3 python3-venv python3-pip \
    zsh tmux fzf ripgrep fd-find bat btop ffmpeg \
    zoxide fastfetch lazygit unzip \
    wl-clipboard openssh-client less xdg-utils \
    libgl1 libgl1-mesa-dri mesa-vulkan-drivers libvulkan1 libglib2.0-0 \
    fonts-noto-color-emoji fonts-noto-cjk locales dbus zenity libnotify-bin \
    android-tools-adb \
    fcitx5 fcitx5-rime fcitx5-chinese-addons fcitx5-frontend-gtk3 fcitx5-frontend-qt5 \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://starship.rs/install.sh | sh -s -- -y

# pyenv is not apt-packaged; /opt keeps it out from under the ${HOME} mount
RUN git clone --depth 1 https://github.com/pyenv/pyenv.git /opt/pyenv && \
    ln -s /opt/pyenv/bin/pyenv /usr/local/bin/pyenv

# yazi is not in Ubuntu repos either; ship the upstream release binary
RUN curl -fsSL https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip -o /tmp/yazi.zip && \
    unzip -q /tmp/yazi.zip -d /tmp && \
    mv /tmp/yazi-x86_64-unknown-linux-gnu/yazi /tmp/yazi-x86_64-unknown-linux-gnu/ya /usr/local/bin/ && \
    rm -rf /tmp/yazi-x86_64-unknown-linux-gnu /tmp/yazi.zip

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8

# D-Bus requires a machine-id; needed so fcitx5 can register org.fcitx.Fcitx5
# (which WeChat's Qt input-context plugin talks to).
RUN [ -s /etc/machine-id ] || (cat /proc/sys/kernel/random/uuid | tr -d - > /etc/machine-id)

ARG USERNAME=kaki
ARG USER_UID=1000
ARG USER_GID=1000

RUN userdel -r ubuntu 2>/dev/null || true \
    && groupdel ubuntu 2>/dev/null || true \
    && groupadd --force --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY entrypoint.fish /entrypoint.fish
RUN chmod +x /entrypoint.fish

USER ${USERNAME}
WORKDIR /home/${USERNAME}

ENV SANDBOX_IN_CONTAINER=1

CMD ["/entrypoint.fish"]
