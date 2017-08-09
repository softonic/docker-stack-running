#!/bin/sh

: ${TIMEOUT:=10}

DOCKER_COMPOSE=docker-compose
if [[ -n "${COMPOSE_FILE}" ]]; then
    DOCKER_COMPOSE="${DOCKER_COMPOSE} -f ${COMPOSE_FILE}"
fi

containers_running() {
    ids=$(${DOCKER_COMPOSE} ps -q 2>/dev/null)
    num_ids=$(echo $ids | wc -w)

    [[ ! -z ${EXPECTED_CONTAINERS+x} ]] && num_ids="${EXPECTED_CONTAINERS}"

    num_ok=0
    for id in $ids; do
        noHealth=$(docker ps -q --filter "id=${id}" --filter "health=none" | wc -l)
        healthy=$(docker ps -q --filter "id=${id}" --filter "health=healthy" | wc -l)
        is_ok=$((noHealth + healthy))
        num_ok=$((num_ok + is_ok))
    done

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
