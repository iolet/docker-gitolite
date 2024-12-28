Container image for Gitolite
============================

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
           --mount type=volume,src=gitolite-home,dst=/var/lib/git,rw=true \
           --publish 8022:8022/tcp \
           --publish 9418:9418/tcp \
           --restart on-failure:3 \
           --detach \
           localhost/iolet/gitolite:3.6.13-alpine3.20.3


Import image
------------

run podman load command import (compressed) image archive

.. code:: bash

	podman load --input /path/to/(compressed)file


Build image
-----------

first create .env file

.. code:: bash

   cp .env.example .env`,

then fill content in `.env`,

last run make command build image.

.. code:: bash

   make tar


FAQ
---

#. When use podman to run, the repo hooks does not work ?

   Please add exec option to volume mount.

#. Why i added new repo in gitolite-admin and pushed, server does not create
   any bare repos in repositories directory.

   Please migrated you commits to master branch, gitolite only handle master
   branch changes, others branch does not any effect.
