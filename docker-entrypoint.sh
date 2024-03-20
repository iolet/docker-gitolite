#!/bin/sh

# Create SSH keys directory if needed
keys_dir=/etc/ssh/keys
if [ ! -d "$keys_dir" ]; then
    mkdir "$keys_dir"
fi

# Setup SSH HostKey if needed
key_file="${keys_dir}/ssh_host_ed25519_key"
conf_dir=/etc/ssh/sshd_config.d
if [ ! -f "$key_file" ]; then
    echo "Generating SSH host key $key_file..."
    ssh-keygen -q -N '' -f "$key_file" -t ed25519
fi
if ! grep -q "HostKey $key_file" "${conf_dir}/20_hostkeys.conf" ; then
    echo "Adding SSH host key $key_file..."
    echo "HostKey $key_file" >> "${conf_dir}/20_hostkeys.conf"
fi

# Setup gitolite admin
auth_keys=~git/.ssh/authorized_keys
if [ ! -f "$auth_keys" ] && [ ! -n "$ADMIN_KEY" ] && [ "${1}" = "/usr/sbin/sshd" ]; then
    echo "You need to specify ADMIN_KEY on first run to setup gitolite"
    echo 'Examples:'
    echo '    docker run --env ADMIN_KEY="$(cat ~/.ssh/id_rsa.pub)" jgiannuzzi/gitolite'
    exit 1
fi
if [ ! -f "$auth_keys" ] && [ -n "$ADMIN_KEY" ] && [ "${1}" = "/usr/sbin/sshd" ]; then
    echo "Initialling gitolite with public key [${ADMIN_KEY}]..."
    echo "$ADMIN_KEY" | tr -d "\n" > "/tmp/admin.pub"
    perl -i -pe 's/^(\s*defaultBranch\s*=\s*)main/\1master/' /etc/gitconfig
    su - git -c "gitolite setup --pubkey /tmp/admin.pub"
    rm "/tmp/admin.pub"
    perl -i -pe 's/^(\s*defaultBranch\s*=\s*)master/\1main/' /etc/gitconfig
fi

# Clean temp variables
unset keys_dir key_file conf_dir auth_keys

# Check setup and fix permissions at every sshd startup
if [ "${1}" = "/usr/sbin/sshd" ]; then
    echo "Checking gitolite initialization..."
    su - git -c "gitolite setup"
    echo "Fixing gitolite data permissions..."
    chown -R git:git ~git
fi

exec "$@"
