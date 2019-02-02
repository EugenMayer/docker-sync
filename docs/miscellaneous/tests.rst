Tests
=====

Automated integration tests
---------------------------

.. code-block:: shell

    bundle install
    bundle exec rspec --format=documentation

Manual Tests (sync and performance)
-----------------------------------

.. tip::

    You can also use the docker-sync-boilerplate_.

Pull this repo and then

.. code-block:: shell

    cd docker-sync/example
    thor stack:start

Open a new shell and run

.. code-block:: shell

    cd docker-sync/example
    echo "NEWVALUE" >> data1/somefile.txt
    echo "NOTTHEOTHER" >> data2/somefile.txt

Check the docker-compose logs and you see that the files are updated.

Performance write test:

.. code-block:: shell

    docker exec -i -t fullexample_app time dd if=/dev/zero of=/var/www/test.dat bs=1024 count=100000

.. _docker-sync-boilerplate: https://github.com/EugenMayer/docker-sync-boilerplate
