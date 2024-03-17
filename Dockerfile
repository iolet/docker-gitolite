FROM alpine:3.19.1

ARG APK_MIRROR=https://dl-cdn.alpinelinux.org

# Install OpenSSH server and Gitolite
# Unlock the automatically-created git user
# Disable sftp subsystem
RUN set -x \
    && [ 'https://dl-cdn.alpinelinux.org' = "${APK_MIRROR}" ] || sed -i "s!https://dl-cdn.alpinelinux.org!${APK_MIRROR}!g" /etc/apk/repositories \
    && apk add --no-cache gitolite openssh \
    && [ 'https://dl-cdn.alpinelinux.org' = "${APK_MIRROR}" ] || sed -i "s!${APK_MIRROR}!https://dl-cdn.alpinelinux.org!g" /etc/apk/repositories \
    && echo "git:*" | chpasswd -e \
    && perl -i -pe 's/^(Subsystem\ssftp\s)/#\1/' /etc/ssh/sshd_config

# Copy nessary files
COPY 10_gitolite.conf 20_hostkeys.conf /etc/ssh/sshd_config.d/
COPY gitconfig /etc/
COPY docker-entrypoint.sh /

# Volume used to store SSH host keys, generated on first run
VOLUME /etc/ssh/keys

# Volume used to store all Gitolite data (keys, config and repositories), initialized on first run
VOLUME /var/lib/git

# Expose port 22 to access SSH
EXPOSE 22/tcp

# Entrypoint responsible for SSH host keys generation, and Gitolite data initialization
ENTRYPOINT ["/docker-entrypoint.sh"]

# Default command is to run the SSH server
CMD ["/usr/sbin/sshd", "-D", "-e"]
