# Swarm consul wordpress autoscaling

[![CircleCI](https://circleci.com/gh/szymonrychu/swarm_consul_wordpress_autoscaling.svg?style=svg)](https://circleci.com/gh/szymonrychu/swarm_consul_wordpress_autoscaling)

## Overview

The repository contains a solution for problem of scaling application docker containers behind nginx loadbalancer.

Basic idea is to use:
 * registrator,
 * consul
 * consul-template

for:
 * service discovery
 * service key/value store
 * template the necessary config files

Wordpress is an application that we will scale at this scenario.

## How it works:

Docker compose handles all of the automation for us:

1. It spins up 3 virtual networks:
    1. `frontend`
    2. `backend`
    3. `control`

2. Then it spins up containers (ordering is crucial):
    1. `consul`                 (within `control` network)
    2. `consul-template`        (within `control` network)
    3. `registrator`            (within `control` network)
    4. `mysql`                  (within `backend` network)
    5. `wordpress`              (within `backend` and `frontend` networks)
    6. `nginx loadbalancer`     (within `frontend` network)

    Thanks to such ordering we can be sure, that registrator, consul and consul-template will have enough time to initialize and start registering services inside of the stack.

3. Once `registrator` get's information from `docker.sock` socket file mounted inside of the container that each service is up, it tries to register it in `consul`

4. Once `registrator` registers `wordpress` application, record in `consul`'s internal catalog is created

5. The record is picked up by the `consul-template`, which takes the information about all of the hosts with that application and prepares config file based on predefined template.

6. If the template has changed, `consul-template` is also able to run certain commands in the container- in our case it runs a script

7. The script uses the same `docker.sock` socket file to send SIGHUP signal to nginx, which tells it to reload it's config and all free worker threads one by one.

## Build/deployment instructions

### Local development

1. Run `docker-compose build && docker-compose up` for local testing.

### Deployment in swarm

Prerequisites:
* `docker swarm` installed on the machine, initialized and working
* `docker registry` deployed in the swarm and listeining on `5000` port

1. To deploy containers in the `docker swarm` cluster first you have to build the images with `docker-compose build`

2. theb you have to push them to the `docker registry` with `docker-compose push`

3. last step is to inform `docker swarm` that it should deploy new stack with `docker stack deploy --compose-file docker-compose.yaml demo`

4. Additional step to expose the app to the open world is to enable communication on port 443 with the loadbalancer. This can be done with `docker service update demo_lb --publish-add 8443:443` command

### Scaling services in swarm

1. To scale `wordpress` running with `docker-compose scale wordpress=XXX`, where XXX is required amount of containers

2. To scale `wordpress` app in swarm one can use `docker service scale demo_wordpress=XXX`, where XXX is required amount of containers

It's possible to scale nginx loadbalancers, but it's currently not tested and `consul-template` signal sending script doesn't support it yet.

It's not possible to scale `mysql` database in current shape (container without replication).

## What else can be done to make the solution better?

### Configuration

1. Unfortunately wordpress uses docker's internal hostnames to talk to the `mysql` database. Plan was to use consul dns capability for that.

    What can be done to make it work?

    a) `docker-compose` can be ditched in favor of using separate `docker` commands. This would allow to get information about consul's internal ip more reliably and also this could give us ability to use `docker`'s internal mechanism of managing resolv.conf

    b) we can make a template out of `resolv.conf` and over-shadow original (`docker` managed) with volume file managed by `consul-template`. This feels a bit ackward- using one tool to overwrite other's capability.

    c) we can try to hardcode `consul`'s ip in `wordpress`'es resolv.conf statically. This is a hit-or-miss solution. It will work in current circustamces and container ordering.. At the same time it will immediatly fail in any other environment (where there is more consuls in the same network, or simply the address we've chosen is already taken)x

    All of above solutions require us to enable connectivity between `consul` and `wordpress` at least on port `8600/udp`.

    Additional option would be to dynamically generate `wordpress`'es `wp-config.php` file, but it doesn't use `consul` DNS.

2. The solution is pretty heavy, but gives a lot of opportunities to secure and configure endpoints. Simpler (but less secure) methods that would serve pretty much the same purpose are:
    
    a) writing simple python script on our own that would listen on `docker.sock` socket's events and based on what's happening prepare template for us (docker provides really nice `python` library for that).

    b) using `traefik` instead of `consul`, `consul-template`, `registrator` and `nginx`. The service natively supports `docker.sock` based service discovery and there are nice examples describing configuration process.

3. `nginx` should have proper `server_name` configured in the configuration once the solution get's deployed anywhere.

4. Once initial setup is done, `wordpress` shouts about `Error establishing a database connection`. I suspect `mysql` database bootstrap script. One could look at it and check what exactly is happening.

5. Build pipeline tags internal images with address of temporary `docker registry` used for `docker stack` deployment in `docker swarm` running on `CircleCI` worker. The containers shouldn't be tagged with `127.0.0.2:5000` address. Solution would be to stand-up proper `docker registry` somewhere for more than period of building the code and make docker-compose use images from it.

6. Consul should run in cluster

### Security

1. `consul`-`consul-template`-`registrator` communication should be encrypted and secured with encryption key. `Consul` uses gossip protocol to talk to it's servers and agents. It can be secured with consul file (more on that [here](https://www.consul.io/docs/agent/options.html#_encrypt), [here](https://www.consul.io/docs/agent/options.html#ca_file) and [here](https://www.consul.io/docs/agent/options.html#verify_incoming) and [here](https://www.consul.io/docs/agent/options.html#verify_outgoing))

2. `nginx` ssl should be prepared with [`mkcert`](https://github.com/FiloSottile/mkcert) for local development

3. `nginx` ssl used on internet facing environments should be either bought from trusted vendor, or generated with `cert-bot`

4. There are improvements possible in `nginx.conf`- for example once the `wordpress`'es setup process is finished `wp-admin/install.php` endpoint should be closed. Also whole `wp-admin` should be hidden with whitelisted list of ips. There are various other improvements one could make to make the service more secure. I'm no expert in securing up php based applications.