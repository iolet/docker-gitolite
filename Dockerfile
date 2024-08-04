FROM docker.io/library/alpine:3.19.3

# Taget gitolite version (tag)
ARG GL3_VERSION

# Git user and group id
ARG GIT_GID=233
ARG GIT_UID=233

# Apk mirror
ARG REPO_PREFIX=https://dl-cdn.alpinelinux.org

# Install dependencies and tools
RUN set -eux; \
    \
    if [ "${REPO_PREFIX}" != "https://dl-cdn.alpinelinux.org" ]; then \
        sed -i "s@https://dl-cdn.alpinelinux.org@${REPO_PREFIX}@g" /etc/apk/repositories; \
    fi; \
    \
    apk add --no-cache curl git perl openssh-server xz; \
    perl -i -pe 's/^(Subsystem\ssftp\s)/#\1/' /etc/ssh/sshd_config; \
    \
    if [ "${REPO_PREFIX}" != "https://dl-cdn.alpinelinux.org" ]; then \
        sed -i "s@${REPO_PREFIX}@https://dl-cdn.alpinelinux.org@g" /etc/apk/repositories; \
    fi; \
    \
    rm -rf /var/cache/apk/* /tmp/*;

# Install gitolite from source
RUN set -eux; \
    \
    curl \
        --progress-bar \
        --location \
        --output /tmp/v${GL3_VERSION}.tar.gz \
        "https://github.com/sitaramc/gitolite/archive/refs/tags/v${GL3_VERSION}.tar.gz"; \
    \
    tar -C /tmp -zxf /tmp/v${GL3_VERSION}.tar.gz; \
    mkdir /usr/local/lib/gitolite3; \
    /tmp/gitolite-${GL3_VERSION}/install -to /usr/local/lib/gitolite3; \
    echo "${GL3_VERSION}" > /usr/local/lib/gitolite3/VERSION; \
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
VOLUME /etc/ssh/key

# Volume used to store all Gitolite data (keys, config and repositories), initialized on first run
VOLUME /var/lib/git

# Expose port 22 to access SSH
EXPOSE 22/tcp

# Entrypoint responsible for SSH host keys generation, and Gitolite data initialization
ENTRYPOINT ["docker-entrypoint.sh"]

# Default command is to run the SSH server
CMD ["/usr/sbin/sshd", "-D", "-e"]
