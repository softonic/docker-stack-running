# softonic/compose-project-running

Waits until a compose project is running, with a defined timeout.

## Description

This image can be useful in the case you have a CI/CD pipeline and you want to be sure that
your containers are running and ready to receive commands before launch your tests.

For example, imagine you want to execute some integration tests in your image. You could do something like:

``` bash
docker-compose up -d
docker-compose exec my-container /test-everyting
docker-compose down
```

But who can be sure that when you launch the `docker-compose exec` command all the containers are ready?
You could add an `sleep XXX` command before the test execution, but this is not so precise and could
represent a waste of time in your pipeline execution.

If you add the execution of this image before the tests execution you can make the pipe wait just the needed
time that your containers need to initialize.

The same example with the usage of this image could be:

``` bash
docker-compose up -d
docker run --rm \
  -v ${PWD}/.:/project:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -e TIMEOUT=30 \
  -e COMPOSE_PROJECT_NAME=$(basename "$PWD") \
  -e EXPECTED_CONTAINERS=3 \
  softonic/compose-project-is-up
docker-compose exec my-container /test-everyting
docker-compose down
```

## Build

``` bash
docker build -t softonic/compose-project-is-up .
```

## Usage

``` bash
docker run --rm \
  -v ${PWD}/.:/project:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -e TIMEOUT=30 \
  -e COMPOSE_PROJECT_NAME=$(basename "$PWD") \
  -e EXPECTED_CONTAINERS=3 \
  softonic/compose-project-is-up
```

This will assume that in less of 30 seconds there should be 3 containers running.
It's important to bypass the `COMPOSE_PROJECT_NAME` because it's how docker-compose identifies
to which project the containers running in the host belong to the current project.

You need to mount two volumes:

- `${PWD}`: Is your current folder and it allows to image to get the compose files definition.
- `/var/run/docker.sock`: This allows to the image to get the data of the running containers.

### Parameters

- `TIMEOUT`: Max number of seconds before assuming that something gone wrong
- `COMPOSE_PROJECT_NAME`: Project name, recommended value: $(basename "$PWD")
- `EXPECTED_CONTAINERS`: Number of expected containers running.
