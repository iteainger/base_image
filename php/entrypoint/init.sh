#!/usr/bin/env bash

now () {
    date +"%Y-%m-%dT%H:%M:%S.%3N"
}

set -e

if [[ "$DEBUG" == 'true' ]]; then
    set -x
fi

if [[ -n "${PREBOOT}" ]]; then
    echo "[$(now)] preboot ${PREBOOT}"
    source $PREBOOT
fi


stop() {
    echo "Received SIGINT or SIGTERM. Shutting down"
    # Get PID
    pid=$(cat /var/run/services)
    # Set TERM
    kill -SIGTERM ${pid}
    # Wait for exit
    wait ${pid}
    # All done.
    echo -n '' | sudo tee /var/run/services > /dev/null
    echo "Done."
}


trap stop SIGINT SIGTERM

BASEDIR=$(dirname "$0")

sudo touch /var/run/services
for x in $(find $BASEDIR -name '*.sh' -not -path '*/init.sh'); do
    echo "[$(now)] source $x"
    source $x
done

if [[ -n "${POSTBOOT}" ]]; then
    echo "[$(now)] postboot ${POSTBOOT}"
    source $POSTBOOT
fi


echo "[$(now)] boot completed"

if [[ -z $1 ]]; then
    echo "[$(now)] enter interactive mode"
    for sh in /usr/local/bin/nu /bin/nu /bin/bash /bin/sh; do
        if [[ -e $sh ]]; then exec $sh; fi
    done
elif [[ $1 == "srv" ]]; then
    echo "[$(now)] enter srv mode"
    sleep infinity &
    echo -n "$! " | sudo tee -a /var/run/services > /dev/null
    wait -n $(cat /var/run/services) && exit $?
else
    echo "[$(now)] enter batch mode"
    exec $@
fi
