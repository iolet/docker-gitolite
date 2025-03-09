ARG ALPINE_VER

FROM docker.io/library/alpine:${ALPINE_VER}

# Maybe we want mirror for package
ARG APK_MIRROR=https://dl-cdn.alpinelinux.org

# For source tag
ARG GITOLITE_TAG
ARG GOSU_TAG

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
    apk add --no-cache curl git perl openssh-server; \
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

# Install gosu from release
RUN set -eux; \
    \
    cd /tmp; \
    TARGET_ARCH=$(apk --print-arch); \
    \
    if [ 'x86_64' = "$TARGET_ARCH" ]; then \
        TARGET_ARCH=amd64; \
    elif [ 'aarch64' = "$TARGET_ARCH" ]; then \
        TARGET_ARCH=arm64; \
    fi; \
    \
    curl --progress-bar --location --output gosu https://github.com/tianon/gosu/releases/download/${GOSU_TAG}/gosu-${TARGET_ARCH}; \
    curl --progress-bar --location --output gosu.asc https://github.com/tianon/gosu/releases/download/${GOSU_TAG}/gosu-${TARGET_ARCH}.asc; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify gosu.asc gosu; \
	gpgconf --kill all; \
    cp gosu /usr/local/bin/; \
    chmod +x /usr/local/bin/gosu; \
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

# Copy configure and entrypoint files
COPY etc/ /etc/
COPY entrypoint.sh /usr/local/bin/

# Volume used to store SSH host key, generated on first run
VOLUME /etc/ssh/keypair.d

# Volume used to store all Gitolite data (keys, config and repositories), initialized on first run
VOLUME /var/lib/git

# Expose port to access SSH and git daemon
EXPOSE 8022/tcp

# Entrypoint responsible for SSH host keys generation, and Gitolite data initialization
ENTRYPOINT ["entrypoint.sh"]

# Run openssh server
CMD ["/usr/sbin/sshd"]
