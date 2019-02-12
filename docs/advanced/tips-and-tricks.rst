***************
Tips and tricks
***************

HTTP Proxy and DNS
==================

The HTTP Proxy and DNS used in dinghy_ is available as a standalone project dinghy-http-proxy_.  The proxy is based on jwilder's excellent
nginx-proxy_ project, with modifications to make it more suitable for local development work. A DNS resolver is also added. By default it will resolve all ``*.docker`` domains to the Docker VM, but this can be changed.

.. _dinghy: https://github.com/codekitchen/dinghy
.. _dinghy-http-proxy: https://github.com/codekitchen/dinghy-http-proxy
.. _nginx-proxy: https://github.com/jwilder/nginx-proxy

SSH-Agent Forwarding
====================

If you need to access some private git repos or ssh servers, it could be useful to use have a ssh-agent accessible from your containers. `whilp/ssh-agent`_ helps you to do so easily.

.. _whilp/ssh-agent: https://github.com/whilp/ssh-agent

Running composer or other tools like if they were on the host
=============================================================

If you run composer and other tools directly in containers, you could use a combination of the autoenv_ zsh plugin and a simple wrapper script to run it easily directly from the host. In your project folder, create a ``.autoenv.zsh`` file with the name of your container:

.. code-block:: shell

    autostash COMPOSER_CONTAINER='project_fpm_1'

then create a simple function in your ``.zshrc``:


.. code-block:: shell

    composer () {
        if [ ! -z $COMPOSER_CONTAINER ]; then
          docker exec -it ${COMPOSER_CONTAINER} /usr/local/bin/composer --working-dir=/src -vv "$@"
        else
          /usr/local/bin/composer "$@"
        fi
    }

.. _autoenv: https://github.com/Tarrasch/zsh-autoenv

Ignore files in your IDE
========================

It's a good idea to add the temporary sync files to your IDE's ignore list to prevent your IDE from indexing them all the time or showing up in search results. In case of unison and PHPStorm for example just go to Preferences -> File Types -> Ignore files and folders and add ``.unison`` to the pattern.

Don't sync everything
=====================

You should only sync files that you really need on both the host and client side. You will see that the sync performance will improve drastically when you ignore unnecessary files. How and which files to ignore depends on your syncing strategy (rsync/unison/...) and your project.

Example for a PHP Symfony project using unison:

.. code-block:: yaml

    # docker-sync.yml
    syncs:
      appcode-unison-sync:
        ...
        sync_args:
            - "-ignore='Path .idea'"          # no need to send PHPStorm config to container
            - "-ignore='Path .git'"           # ignore the main .git repo
            - "-ignore='BelowPath .git'"      # also ignore .git repos in subfolders such as in composer vendor dirs
            - "-ignore='Path var/cache/*'"    # don't share the cache
            - "-ignore='Path var/sessions/*'" # we don't need the sessions locally
            - "-ignore='Path node_modules/*'" # remove this if you need code completion
            # - "-ignore='Path vendor/*'"     # we could ignore the composer vendor folder, but then you won't have code completion in your IDE
