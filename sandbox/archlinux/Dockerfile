FROM archlinux:latest

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm sudo curl fish neovim \
    starship git cmake make pyenv \
    zoxide fastfetch lazygit yazi \
    which catatonit wl-clipboard \
    openssh base-devel bat btop ffmpeg libxcb mesa glib2 \
    fd firefox less noto-fonts-emoji android-tools scrcpy \
    vulkan-icd-loader vulkan-tools zenity \
    fcitx5 fcitx5-gtk fcitx5-qt fcitx5-rime fcitx5-chinese-addons dbus \
    && \
    rm -rf /var/cache/pacman/pkg/*

# D-Bus requires a machine-id; needed so fcitx5 can register org.fcitx.Fcitx5
# (which WeChat's Qt input-context plugin talks to).
RUN [ -s /etc/machine-id ] || (cat /proc/sys/kernel/random/uuid | tr -d - > /etc/machine-id)

ARG USERNAME=kaki
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd -g ${USER_GID} ${USERNAME} && \
    useradd -m -u ${USER_UID} -g ${USER_GID} -s /bin/bash ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY entrypoint.fish /entrypoint.fish
RUN chmod +x /entrypoint.fish

USER ${USERNAME}
WORKDIR /home/${USERNAME}

ENV SANDBOX_IN_CONTAINER=1

CMD ["/usr/bin/catatonit", "--", "/entrypoint.fish"]
