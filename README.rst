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
           --mount type=volume,src=gitolite-keys,dst=/etc/ssh/keypair.d,rw=true \
           --mount type=volume,src=gitolite-home,dst=/var/local/lib/git,rw=true \
           --publish 2222:22/tcp \
           --restart on-failure:3 \
           --detach \
           iolet/gitolite


Build image
-----------

.. code:: bash

    RELEASE_TAG=3.0

    ALPINE_TAG=3.20.2
    APK_MIRROR=https://mirror.lzu.edu.cn
    GITOLITE_TAG=v3.6.13

    podman build \
        --build-arg "ALPINE_TAG=${ALPINE_TAG}" \
        --build-arg "APK_MIRROR=${APK_MIRROR}" \
        --build-arg "GITOLITE_TAG=${GITOLITE_TAG}" \
        --tag "iolet/gitolite:${RELEASE_TAG}-gl$(echo $GITOLITE_TAG | tr -d 'v')-alpine${ALPINE_TAG}" \
        .

Transfer image
--------------

.. code:: bash

    # export image with compression
    podman save localhost/iolet/gitolite:latest | zstd - > iolet_gitolite_latest.tar.zst

    # import images directly
    podman load --input iolet_gitolite_latest.tar.zst

FAQ
-----

#. When use podman to run, the repo hooks does not work ?

   Please add exec option to volume mount.

#. Why i added new repo in gitolite-admin and pushed, server does not create
   any bare repos in repositories directory.

   Please migrated you commits to master branch, gitolite only handle master
   branch changes, others branch does not any effect.
