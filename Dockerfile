ARG ALPINE_VER

FROM docker.io/library/alpine:${ALPINE_VER}

# Maybe we want mirror for package
ARG APK_MIRROR=https://dl-cdn.alpinelinux.org

# For source tag
ARG GITOLITE_TAG
ARG S6_OVERLAY_TAG

# Git user and group id
ARG GIT_GID=201
ARG GIT_UID=201

# Install dependencies and tools
RUN set -eux; \
    \
    if [ -n "${APK_MIRROR}" ] && [ "${APK_MIRROR}" != "https://dl-cdn.alpinelinux.org" ]; then \
        sed -i "s@https://dl-cdn.alpinelinux.org@${APK_MIRROR}@g" /etc/apk/repositories; \
    fi; \
    \
    apk add --no-cache curl git git-daemon perl tree openssh-server; \
    perl -i -pe 's/^(Subsystem\ssftp\s)/#\1/' /etc/ssh/sshd_config; \
    \
    if [ -n "${APK_MIRROR}" ] && [ "${APK_MIRROR}" != "https://dl-cdn.alpinelinux.org" ]; then \
        sed -i "s@${APK_MIRROR}@https://dl-cdn.alpinelinux.org@g" /etc/apk/repositories; \
    fi; \
    \
    rm -rf /var/cache/apk/* /tmp/*;

# Install gitolite from source
RUN set -eux; \
    \
    git clone --branch "${GITOLITE_TAG}" --depth 1 --single-branch \
        https://github.com/sitaramc/gitolite.git /tmp/gitolite; \
    \
    mkdir /usr/local/lib/gitolite3; \
    /tmp/gitolite/install -to /usr/local/lib/gitolite3; \
    ln -s /usr/local/lib/gitolite3/gitolite /usr/local/bin/gitolite; \
    \
    rm -rf /tmp/*;

RUN set -eux; \
    \
    cd /tmp; \
    \
    curl --progress-bar --location --remote-name https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_TAG}/s6-overlay-noarch.tar.xz; \
    curl --progress-bar --location --remote-name https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_TAG}/s6-overlay-noarch.tar.xz.sha256; \
    sha256sum -c -s s6-overlay-noarch.tar.xz.sha256; \
    tar -C / -Jxpf s6-overlay-noarch.tar.xz; \
    \
    curl --progress-bar --location --remote-name https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_TAG}/s6-overlay-x86_64.tar.xz; \
    curl --progress-bar --location --remote-name https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_TAG}/s6-overlay-x86_64.tar.xz.sha256; \
    sha256sum -c -s s6-overlay-x86_64.tar.xz.sha256; \
    tar -C / -Jxpf s6-overlay-x86_64.tar.xz; \
    \
    rm -rf /tmp/*;

# Setup special user and group
RUN set -eux; \
    \
    addgroup --gid ${GIT_GID} git; \
    adduser \
        --disabled-password \
        --shell /bin/ash \
        --home /var/lib/git \
        --uid ${GIT_UID} \
        --gecos git \
        --ingroup git \
        git;

# Copy configure and entry files
COPY /etc/ /etc/
COPY entrypoint.sh /usr/local/bin

# Volume used to store SSH host key, generated on first run
VOLUME /etc/ssh/keypair.d

# Volume used to store all Gitolite data (keys, config and repositories), initialized on first run
VOLUME /var/lib/git

# Expose port to access SSH
EXPOSE 8022/tcp
EXPOSE 9418/tcp

# Entrypoint responsible for SSH host keys generation, and Gitolite data initialization
ENTRYPOINT ["entrypoint.sh"]

# Default command to run s6-overlay
CMD ["/init"]
