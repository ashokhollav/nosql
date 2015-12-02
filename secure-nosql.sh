#!/bin/bash
docker stop data-container
docker rm data-container
docker stop node1 node2 node3 dns client node4
docker rm node1 node2 node3 dns client node4

# run a data only container
docker create   -v /data --name data-container busybox /bin/sh

# run phensley's dns server
docker run -d --name dns -v /var/run/docker.sock:/docker.sock phensley/docker-dns  --domain example.com

# start nodes
# the containers entrypoint runs the makebootconfig script present @ /home/oracle/scripts
# capacity is 1 and memory_mb is 512
# port mapping is done mainly to monitor nosql from the host, though it is not required, dynami ports are just fine

docker run -d --name node1 -h node1 --volumes-from data-container -p 5000:5000 -p 5001:5001 --dns $(docker inspect -f '{{.NetworkSettings.IPAddress}}' dns)  --dns-search example.com ashokhollav/nosql makesecure
docker run -d --name node2 -h node2 --volumes-from data-container -p 6000:5000 -p 6001:5001 --dns $(docker inspect -f '{{.NetworkSettings.IPAddress}}' dns)  --dns-search example.com ashokhollav/nosql makesecure
docker run -d --name node3 -h node3 --volumes-from data-container -p 7000:5000 -p 7001:5001 --dns $(docker inspect -f '{{.NetworkSettings.IPAddress}}' dns)  --dns-search example.com ashokhollav/nosql makesecure

sleep 5
docker exec -it node1 bash /home/oracle/scripts/securityscripts/3.configure.sh localhost
docker exec -it node1 bash /home/oracle/scripts/securityscripts/runScript.sh node1 3x1
docker exec -it node1 bash cd /home/oracle/scripts/securityscripts/
