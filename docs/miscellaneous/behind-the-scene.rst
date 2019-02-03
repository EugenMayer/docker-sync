Behind the Scene
================

Behind the scenes / architecture
--------------------------------

On the host, a thor based ruby task is started, this starts:

    - Every sync will start an own docker-container with a rsync/unison-daemon watching for connections.
    - The data gets pre-synced on sync-start
    - A fswatch cli-task gets setup, to run rsync/unison on each file-change in the source-folder you defined

Done. No magic. But its roadrunner fast! And it has no pre-conditions on your actual stack.
