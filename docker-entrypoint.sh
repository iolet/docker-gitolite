#!/bin/sh

# Check argument first
if [ "/usr/sbin/sshd" = "${1}" ]; then
    is_sshd=1
else
    is_sshd=0
fi

# Setup ssh host key dirs
keys_dir=/etc/ssh/keys
if [ $is_sshd -eq 1 ] && [ ! -d "$keys_dir" ]; then
    mkdir "$keys_dir"
fi

# Setup ssh host key
key_file="${keys_dir}/ssh_host_ed25519_key"
if [ $is_sshd -eq 1 ] && [ ! -f "$key_file" ] && [ ! -n "$HOSTD_KEY" ]; then
    echo "Generating ssh host ed25519 key..."
    ssh-keygen -q -N '' -f "$key_file" -t ed25519
fi
if [ $is_sshd -eq 1 ] && [ ! -f "$key_file" ] && [ -n "$HOSTD_KEY" ]; then
    echo "Installing ssh host ed25519 key..."
    echo "$HOSTD_KEY" > "$key_file"
    chmod 600 "$key_file"
    ssh-keygen -y -f "$key_file" > "${key_file}.pub"
fi

# Enable ssh host key
con_file=/etc/ssh/sshd_config.d/20_hostkeys.conf
if [ $is_sshd -eq 1 ] && ! grep -q "HostKey $key_file" "${con_file}"; then
    echo "Appending ssh host ed25519 key..."
    echo "HostKey $key_file" >> "${con_file}"
fi

# Setup gitolite admin
auth_keys=~git/.ssh/authorized_keys
if [ $is_sshd -eq 1 ] && [ ! -f "$auth_keys" ] && [ ! -n "$ADMIN_KEY" ]; then
    echo "You need to specify ADMIN_KEY on first run to setup gitolite"
    echo 'Examples:'
    echo '    docker run --env ADMIN_KEY="$(cat ~/.ssh/id_rsa.pub)" iolet/gitolite'
    exit 1
fi
if [ $is_sshd -eq 1 ] && [ ! -f "$auth_keys" ] && [ -n "$ADMIN_KEY" ]; then
    echo "Initialling gitolite with public key [${ADMIN_KEY}]..."
    echo "$ADMIN_KEY" | tr -d "\n" > "/dev/shm/admin.pub"
    su - git -c "gitolite setup --pubkey /dev/shm/admin.pub"
    rm "/dev/shm/admin.pub"
fi

# Check setup and fix permissions at every sshd startup
if [ $is_sshd -eq 1 ]; then
    echo "Checking gitolite initialization..."
    su - git -c "gitolite setup"
    echo "Fixing gitolite data permissions..."
    chown -R git:git ~git
fi

# Clean temp variables
unset is_sshd keys_dir key_file con_file auth_keys

exec "$@"
