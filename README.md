# softonic/stack-is-up

Waits until a stack is running, with a defined timeout.

## Description

This image can be useful in the case you have a CI/CD pipeline and you want to be sure that
your containers are running and ready to receive commands before launch your tests.

For example, imagine you want to execute some integration tests in your image. You could do something like:

``` bash
docker stack deploy -f docker-compose.yml mystack
// Run feature tests.
docker stack rm mystack
```

But who can be sure that when you launch the tests command all the containers are ready?
You could add an `sleep XXX` command before the test execution, but this is not so precise and could
represent a waste of time in your pipeline execution.

If you add the execution of this image before the tests execution you can make the pipe wait just the needed
time that your containers need to initialize.

## Build

``` bash
docker build -t softonic/stack-is-up .
```

## Usage

``` bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -e TIMEOUT=30 \
  -e STACK_NAME=myStack \
  softonic/stack-is-up
```

This will assume that in less of 30 seconds there should be 3 containers running.
It's important to bypass the `STACK_NAME` because it's how docker stack identifies
to which project the containers running in the host belong to the current project.

You need to mount two volumes:

- `/var/run/docker.sock`: This allows to the image to get the data of the running containers.

### Parameters

- `TIMEOUT`: Max number of seconds before assuming that something gone wrong
- `STACK_NAME`: Stack name
- `VERBOSE`: Output container name if activated (1 for active, 0 for disabled. Defaults to 0)
