#!/bin/sh

: ${TIMEOUT:=10}
: ${VERBOSE:=0}

DOCKER_COMPOSE=docker-compose
if [[ -n "${COMPOSE_FILE}" ]]; then
    DOCKER_COMPOSE="${DOCKER_COMPOSE} -f ${COMPOSE_FILE}"
fi

[[ ! -z ${EXPECTED_CONTAINERS+x} ]] && num_ids="${EXPECTED_CONTAINERS}"

containers_running() {
    ids=$(${DOCKER_COMPOSE} ps -q 2>/dev/null)

    [[ -z ${num_ids} ]] && num_ids=$(echo $ids | wc -w)

    num_ok=0
    for id in $ids; do
        noHealth=$(docker ps -q --filter "id=${id}" --filter "health=none" | wc -l)
        healthy=$(docker ps -q --filter "id=${id}" --filter "health=healthy" | wc -l)
        is_ok=$((noHealth + healthy))
        num_ok=$((num_ok + is_ok))
        is_dead=$(docker ps -q -a --filter "id=${id}" --filter=status=exited | wc -l)

        if [ ${is_dead} -gt 0 ]; then
            dead_ids=$(docker ps -q -a --filter "id=${id}" --filter=status=exited)
            for did in $dead_ids; do
                consumer_name=$(docker ps -a --filter="id=${did}" --format="{{ .Names }}")
                echo -e "\nERROR: Container '$consumer_name' is DEAD\n"
                docker logs ${id} | tail -n100
            done
            exit 1
        fi

        if [ ${VERBOSE} -eq 1 ]; then
            docker ps --filter "id=${id}" --format="{{ .Names }} {{ .Status }}"
        fi
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
