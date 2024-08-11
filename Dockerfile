ARG ALPINE_TAG

FROM docker.io/library/alpine:${ALPINE_TAG}

# Maybe we want mirror for package
ARG APK_MIRROR=https://dl-cdn.alpinelinux.org

# For gitolite tag
ARG GITOLITE_TAG

# Git user and group id
ARG GIT_GID=233
ARG GIT_UID=233

# Install dependencies and tools
RUN set -eux; \
    \
    if [ "${APK_MIRROR}" != "https://dl-cdn.alpinelinux.org" ]; then \
        sed -i "s@https://dl-cdn.alpinelinux.org@${APK_MIRROR}@g" /etc/apk/repositories; \
    fi; \
    \
    apk add --no-cache git perl openssh-server; \
    perl -i -pe 's/^(Subsystem\ssftp\s)/#\1/' /etc/ssh/sshd_config; \
    \
    if [ "${APK_MIRROR}" != "https://dl-cdn.alpinelinux.org" ]; then \
        sed -i "s@${APK_MIRROR}@https://dl-cdn.alpinelinux.org@g" /etc/apk/repositories; \
    fi; \
    \
    rm -rf /var/cache/apk/* /tmp/*;

# Install gitolite from source
RUN set -eux; \
    \
    git clone https://github.com/sitaramc/gitolite.git \
        --branch "${GITOLITE_TAG}" \
        --depth 1 \
        --single-branch \
        --no-checkout; \
    \
    mkdir /usr/local/lib/gitolite3; \
    /tmp/gitolite/install -to /usr/local/lib/gitolite3; \
    ln -s /usr/local/lib/gitolite3/gitolite /usr/local/bin/gitolite; \
    \
    rm -rf /tmp/*;

# Setup special user and group
RUN set -eux; \
    addgroup \
        --gid ${GIT_GID} \
        --system \
        git; \
    adduser \
        --uid ${GIT_UID} \
        --shell /bin/ash \
        --home /var/lib/git \
        --gecos git \
        --ingroup git \
        --system \
        --disabled-password \
        git; \
    echo "git:*" | chpasswd -e; \
    sed -i 's/[1-9]\+//g' /etc/shadow; \
    sed -i 's/[1-9]\+//g' /etc/shadow-;

# Copy nessary files
COPY 10_gitolite.conf 20_hostkeys.conf /etc/ssh/sshd_config.d/
COPY gitconfig /etc/
COPY docker-entrypoint.sh /usr/local/bin

# Volume used to store SSH host key, generated on first run
VOLUME /etc/ssh/keypair.d

# Volume used to store all Gitolite data (keys, config and repositories), initialized on first run
VOLUME /var/local/lib/git

# Expose port 22 to access SSH
EXPOSE 22/tcp

# Entrypoint responsible for SSH host keys generation, and Gitolite data initialization
ENTRYPOINT ["docker-entrypoint.sh"]

# Default command is to run the SSH server
CMD ["/usr/sbin/sshd", "-D", "-e"]
