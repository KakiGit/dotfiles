FROM archlinux:latest

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm sudo curl fish neovim starship git cmake make pyenv zoxide fastfetch lazygit yazi which catatonit && \
    rm -rf /var/cache/pacman/pkg/*

ARG USERNAME
ARG USER_UID
ARG USER_GID

RUN groupadd -g ${USER_GID} ${USERNAME} && \
    useradd -m -u ${USER_UID} -g ${USER_GID} -s /bin/bash ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER ${USERNAME}
WORKDIR /home/${USERNAME}

CMD ["/usr/bin/catatonit", "--", "/entrypoint.sh"]
