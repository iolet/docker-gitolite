Container image for Gitolite
=============================

This project is based on `jgiannuzzi/docker-gitolite <https://github.com/jgiannuzzi/docker-gitolite>`_
and enhanced security.

Quick setup
-----------

#. Create volumes for your SSH host keys and Gitolite data

   .. code:: bash

       podman volume create gitolite-keys
       podman volume create gitolite-home


#. Start your Gitolite container with admin SSH public key

   .. code:: bash

       ADMIN_KEY=$(cat ./id_ed25519.pub)

       podman run \
           --name gitolite \
           --env "ADMIN_KEY=${ADMIN_KEY}" \
           --mount type=volume,src=gitolite-keys,dst=/etc/ssh/keys,rw=true \
           --mount type=volume,src=gitolite-home,dst=/var/lib/git,rw=true \
           --publish 2222:22/tcp \
           --restart on-failure:3 \
           --detach \
           iolet/gitolite


Build image
-----------

.. code:: bash

    RELEASE_TAG=2.0

    GL3_VERSION=3.6.13
    REPO_PREFIX=https://mirror.lzu.edu.cn

    podman build \
        --build-arg "GL3_VERSION=${GL3_VERSION}" \
        --build-arg "REPO_PREFIX=${REPO_PREFIX}" \
        --tag "iolet/gitolite:${RELEASE_TAG}-gl${GL3_VERSION}-alpine3.19.1" \
        .

FAQ
-----

#. When use podman to run, the repo hooks does not work ?

   Please add exec option to volume mount.

#. Why i added new repo in gitolite-admin and pushed, server does not create
   any bare repos in repositories directory.

   Please migrated you commits to master branch, gitolite only handle master
   branch changes, others branch does not any effect.
