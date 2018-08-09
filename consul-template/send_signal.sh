#!/bin/sh -e
container_id=$(/docker/docker ps --filter "name=$1" --format "{{.ID}}")
if [ -n "$container_id" ]; then
    echo "killing SIGHUP $container_id"
    /docker/docker kill --signal=SIGHUP $container_id
fi