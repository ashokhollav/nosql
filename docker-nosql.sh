#!/bin/bash
docker stop data-container
docker rm data-container
docker stop node1 node2 node3 dns client
docker rm node1 node2 node3 dns client

# run a data only container
docker create   -v /data --name data-container busybox /bin/sh

# run phensley's dns server
docker run -d --name dns -v /var/run/docker.sock:/docker.sock phensley/docker-dns  --domain example.com

# start nodes
# the containers entrypoint runs the makebootconfig script present @ /home/oracle/scripts
# capacity is 1 and memory_mb is 512
# port mapping is done mainly to monitor nosql from the host, though it is not required, dynami ports are just fine

docker run -d --name node1 -h node1 -p 5000:5000 -p 5001:5001 --dns $(docker inspect -f '{{.NetworkSettings.IPAddress}}' dns)  --dns-search example.com ashokhollav/nosql
docker run -d --name node2 -h node2 -p 6000:5000 -p 6001:5001 --dns $(docker inspect -f '{{.NetworkSettings.IPAddress}}' dns)  --dns-search example.com ashokhollav/nosql
docker run -d --name node3 -h node3 -p 7000:5000 -p 7001:5001 --dns $(docker inspect -f '{{.NetworkSettings.IPAddress}}' dns)  --dns-search example.com ashokhollav/nosql

# start the client and deploy plan, this process will deploy a 3x1 nosql cluster
docker run -i -t --rm --name client -h client --dns $(docker inspect -f '{{.NetworkSettings.IPAddress}}' dns)  --dns-search example.com ashokhollav/nosql plan node1 3x1
# start client for using nosql, sample programs are present in /home/oracle/exercises
docker run -it --rm --name client -h client --dns $(docker inspect -f '{{.NetworkSettings.IPAddress}}' dns)  --dns-search example.com ashokhollav/nosql bash
