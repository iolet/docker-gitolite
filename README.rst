Docker image for Gitolite
=========================

This project is based on `jgiannuzzi/docker-gitolite <https://github.com/jgiannuzzi/docker-gitolite>`_
and enhanced security.

Quick setup
-----------

#. Create volumes for your SSH host keys and Gitolite data

   .. code:: bash

       docker volume create --name gitolite-keys
       docker volume create --name gitolite-home


#. Start your Gitolite container with admin SSH public key

   .. code:: bash

       docker run \
           --name gitolite \
           --env ADMIN_KEY="$(cat ./admin@gitolite.pub)" \
           --env HOSTD_KEY="$(cat ./ssh_host_ed25519_key)" \
           --mount type=volume,source=gitolite-keys,target=/etc/ssh/keys \
           --mount type=volume,source=gitolite-home,target=/var/lib/git \
           --publish 2222:22/tcp \
           --restart unless-stopped \
           --detach \
           iolet/gitolite:latest


Build image
-----------

.. code:: bash

    APK=https://ap.edge.kernel.org
    TAG=1.0-alpine3.19.1

    docker build \
        --build-arg "APK_MIRROR=${APK}" \
        --tag "ioloet/gitolite:${TAG}" .

FAQ
-----

#. When use podman to run, the repo hooks does not work ?

   Please add exec option to volume mount.

#. Why i added new repo in gitolite-admin and pushed, server does not create
   any bare repos in repositories directory.

   Please migrated you commits to master branch, gitolite only handle master
   branch changes, others branch does not any effect.
