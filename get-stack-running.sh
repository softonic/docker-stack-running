#!/bin/sh

: ${TIMEOUT:=10}
: ${VERBOSE:=0}
: ${STACK_NAME:=}

if [ -z "$STACK_NAME" ]
then
    echo "STACK_NAME environment variable is required."
    exit 1
fi

containers_running() {
    services=$(docker stack ps ${STACK_NAME} --filter='desired-state=running' | tail -n+2 | awk '{ print $5}');
    num_ok=$(echo $services | tr " " "\n" | grep 'Running' | wc -l)
    num_ids=$(echo $services | tr " " "\n" | wc -l)

    if [ "$num_ids" -gt 0 ] && [ "$num_ok" -eq "$num_ids" ]; then
        echo >&2 "Containers running (${num_ok}/${num_ids})!"
        return 0
    else
        echo >&2 "Waiting initialization (${num_ok}/${num_ids}) ${TIMEOUT}"
        return 1
    fi
}

while [ $TIMEOUT -gt 0 ]
do
    if containers_running; then
        break
    fi
    sleep 1
    TIMEOUT=$(( $TIMEOUT - 1 ))
done
if [ "$TIMEOUT" = 0 ]; then
    echo >&2 'Container initialization failed'
    exit 1
fi
