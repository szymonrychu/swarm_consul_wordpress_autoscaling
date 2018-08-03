#!/bin/sh
container_id=$(/docker/docker ps --filter "name=$1" --format "{{.ID}}")
echo "killing SIGHUP $container_id"
/docker/docker kill --signal=SIGHUP $container_id
exit $?