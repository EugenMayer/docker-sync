#!/bin/sh

echo "$1"

if [ "$1" == "watch" ]; then
    run_with_user=www-data

    # prevent error if uid is already in use
    if ! cut -d: -f3 /etc/passwd | grep -q $(stat -c '%u' /data); then
        adduser -u $(stat -c '%u' /data) -D www-data
    else
        $run_with_user=$(awk -F: "/:$UNISON_OWNER_UID:/{print \$1}" /etc/passwd)
    fi

    while true; do
        su $run_with_userr -c 'date >> /data/filefromcontainer.txt';
        sleep 5;
    done
fi



exec "$@"