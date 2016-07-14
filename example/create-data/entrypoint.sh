#!/bin/sh

echo "$1" > /command.txt

if [ "$1" == "watch" ]; then
    adduser -u $(stat -c '%u' /data) -D www-data

    while true; do
        su www-data -c 'date >> /data/filefromcontainer.txt';
        sleep 5;
    done
fi



exec "$@"