Docker image for Gitolite
=========================

This image allows you to run a git server in a container with OpenSSH and
`Gitolite <https://github.com/sitaramc/gitolite#readme>`_.

Based on Alpine Linux.

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
           --env ADMIN_KEY="$(cat ~/admin-keys@gitolite.pub)" \
           --mount type=volume,source=gitolite-keys,target=/etc/ssh/keys \
           --mount type=volume,source=gitolite-home,target=/var/lib/git \
           --publish 2222:22/tcp \
           --restart unless-stopped \
           --detach \
           liding/gitolite:latest


Build image
-----------

.. code:: bash

    docker build \
        --build-arg APK_MIRROR=https://ap.edge.kernel.org \
        --tag liding/gitolite:latest .

FAQ
-----

#. When use podman to run, please add exec option to volume mount,
   otherwrise the repo hooks will not work

   You can then add users and repos by following
   the `official guide <https://github.com/sitaramc/gitolite#adding-users-and-repos>`_.

#. Why i added new repo in gitolite-admin and pushed, server does not create
   any bare repos in repositories directory.

   Please migrated you commits to master branch, gitolite only handle master
   branch changes, other branches does not any effect.
