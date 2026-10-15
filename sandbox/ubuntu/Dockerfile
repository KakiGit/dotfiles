FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    sudo curl ca-certificates git fish neovim \
    build-essential cmake make \
    python3 python3-venv python3-pip \
    zsh tmux fzf ripgrep fd-find bat btop ffmpeg \
    wl-clipboard openssh-client less xdg-utils \
    libgl1 libgl1-mesa-dri mesa-vulkan-drivers libvulkan1 libglib2.0-0 \
    fonts-noto-color-emoji fonts-noto-cjk locales dbus zenity libnotify-bin \
    android-tools-adb \
    fcitx5 fcitx5-rime fcitx5-chinese-addons fcitx5-frontend-gtk3 fcitx5-frontend-qt5 \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://starship.rs/install.sh | sh -s -- -y

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
