ARG ALPINE_VER

FROM docker.io/library/alpine:${ALPINE_VER} as builder

# Maybe we want mirror for package
ARG APK_MIRROR=https://dl-cdn.alpinelinux.org
ARG GH_ENDPOINT=https://github.com

# For source tag
ARG GITOLITE_TAG
ARG GOSU_TAG

# Install dependencies and tools
RUN set -eux; \
    \
    if [ -n "${APK_MIRROR}" ] && [ "${APK_MIRROR}" != "https://dl-cdn.alpinelinux.org" ]; then \
        sed -i "s@https://dl-cdn.alpinelinux.org@${APK_MIRROR}@g" /etc/apk/repositories; \
    fi; \
    \
    apk add --no-cache curl git gpg gpg-agent perl;

# Install gitolite from source
RUN set -eux; \
    \
    TARGET_BRANCH="v${GITOLITE_TAG##*v}"; \
    \
    git clone --branch "${TARGET_BRANCH}" --depth 1 --single-branch \
        $GH_ENDPOINT/sitaramc/gitolite.git /tmp/gitolite; \
    \
    mkdir /usr/local/lib/gitolite3; \
    \
    /tmp/gitolite/install -to /usr/local/lib/gitolite3;

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
    curl --progress-bar --location --output gosu $GH_ENDPOINT/tianon/gosu/releases/download/${GOSU_TAG}/gosu-${TARGET_ARCH}; \
    curl --progress-bar --location --output gosu.asc $GH_ENDPOINT/tianon/gosu/releases/download/${GOSU_TAG}/gosu-${TARGET_ARCH}.asc; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify gosu.asc gosu; \
	gpgconf --kill all; \
    cp gosu /usr/local/bin/; \
    chmod +x /usr/local/bin/gosu;

# Disable gitweb and Enable cgit by default
RUN set -eux; \
    \
    sed -i "s/'gitweb'/# 'gitweb'/g" /usr/local/lib/gitolite3/lib/Gitolite/Rc.pm; \
    sed -i "s/# 'cgit'/'cgit'/g" /usr/local/lib/gitolite3/lib/Gitolite/Rc.pm;

FROM docker.io/library/alpine:${ALPINE_VER}

# Inherited previous stage arg variable value
ARG APK_MIRROR

# Git user gid and uid
ARG GIT_GID=201
ARG GIT_UID=201

# Copy sudo and gitolite files
COPY --from=builder /usr/local/bin/gosu /usr/local/bin/
COPY --from=builder /usr/local/lib/gitolite3/ /usr/local/lib/gitolite3/

# Install dependencies and tools
RUN set -eux; \
    \
    if [ -n "${APK_MIRROR}" ] && [ "${APK_MIRROR}" != "https://dl-cdn.alpinelinux.org" ]; then \
        sed -i "s@https://dl-cdn.alpinelinux.org@${APK_MIRROR}@g" /etc/apk/repositories; \
    fi; \
    \
    apk add --no-cache git perl openssh-server tzdata; \
    \
    if [ -n "${APK_MIRROR}" ] && [ "${APK_MIRROR}" != "https://dl-cdn.alpinelinux.org" ]; then \
        sed -i "s@${APK_MIRROR}@https://dl-cdn.alpinelinux.org@g" /etc/apk/repositories; \
    fi; \
    \
    rm -rf /var/cache/apk/* /tmp/*;

# Enhanced security and convenience
RUN set -eux; \
    \
    perl -i -pe 's/^(Subsystem\ssftp\s)/#\1/' /etc/ssh/sshd_config; \
    \
    ln -s /usr/local/lib/gitolite3/gitolite /usr/local/bin/gitolite;

# Setup user and group
RUN set -eux; \
    addgroup \
        --gid ${GIT_GID} \
        git; \
    \
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
COPY entrypoint.sh gl-export.sh gl-import.sh /usr/local/bin/

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
