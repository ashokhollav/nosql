The Oracle NoSQL Database is a distributed key-value database. It is designed to provide highly reliable, scalable and available data storage across a configurable set of systems that function as storage nodes.

Data is stored as key-value pairs, which are written to particular storage node(s), based on the hashed value of the primary key. Storage nodes are replicated to ensure high availability, rapid failover in the event of  a node failure and optimal load balancing of queries. Customer applications are written using an easy-to-use Java/C API to read and write data.
 
Oracle NoSQL Driver links with the customer application, providing access to the data via appropriate storage node for the requested key.  A web based console as well as command line interface is available for easy administration of the cluster.

This image is based on centos:latest and has nosql software installed. Each container of this image represents a node in the nosql cluster. I have attached scripts that will spawn a 3x1 nosql cluster. To add more nodes run the addnode.sh script. Point to be noted is that the scripts assume node names to be in "node"<number> format, ex: node1, node2, node3 etc.
This assumption is made to make scripting simpler, however there is no such rule made by the product itself.


To spawn a 3 node 1 shard nosql cluster execute the docker-nosql.sh script
#docker-nosql.sh
The script runs a dns server and attaches the ip address of the dns server to the nodes when bringing them up. I am using phensley's dns server, any other should work just fine (as long as --dns attribute is updated)

-- run phensley's dns server
docker run -d --name dns -v /var/run/docker.sock:/docker.sock phensley/docker-dns  --domain example.com

-- start nodes
-- the containers entrypoint runs the makebootconfig script present @ /home/oracle/scripts
-- capacity is 1 and memory_mb is 512
-- port mapping is done mainly to monitor nosql from the host, though it is not required, dynami ports are just fine

docker run -d --name node1 -h node1 -p 5000:5000 -p 5001:5001 --dns $(docker inspect -f '{{.NetworkSettings.IPAddress}}' dns)  --dns-search example.com nosql:1.0
docker run -d --name node2 -h node2 -p 6000:5000 -p 6001:5001 --dns $(docker inspect -f '{{.NetworkSettings.IPAddress}}' dns)  --dns-search example.com nosql:1.0
docker run -d --name node3 -h node3 -p 7000:5000 -p 7001:5001 --dns $(docker inspect -f '{{.NetworkSettings.IPAddress}}' dns)  --dns-search example.com nosql:1.0

-- start the client and deploy plan, this process will deploy a 3x1 nosql cluster
docker run -i -t --rm --name client -h client --dns $(docker inspect -f '{{.NetworkSettings.IPAddress}}' dns)  --dns-search example.com nosql:1.0 plan node1 3x1
-- start client for using nosql, sample programs are present in /home/oracle/exercises
docker run -it --rm --name client -h client --dns $(docker inspect -f '{{.NetworkSettings.IPAddress}}' dns)  --dns-search example.com nosql:1.0 bash

After docker-nosql.sh exits, you will have a fully configured 3x1 nosql cluster. You will be presented with a shell of a client container within which you can execute exercises.

#updatedns
Since I am using a container based dns server, it is possible that the dns server's ip address change when it is stopped and started, hence there is a need to update the /etc/resolv.conf in every nosql container with the updated dns ipaddress (in oracle nosql nodes of the replica group communicate with each other)
hence the script #updatedns. 
The script does the following

1. finds out list of nosql containers using docker ps -q

2. for every container run docker exec -i -t $container /home/oracle/scripts/updatedns <dnsip>

3. the updatedns script inside the container updates the /etc/resolv.conf

#addnode.sh
To add a new node to the cluster run ./addnode.sh <number>, <number> is a numeric identifier of the node, which basically is the next number in the sequence of nodes already spawned.

ex: ./addnode.sh 4, spawns a nosql container with hostname set to node4 and name set to node4

#container

The container itself has scripts and basic exercises to get you upto speed. I have currently not implemented persistent storage, so data will be lost once container is killed.

in the /home/oracle/scripts directory there are nosql deployment scripts, 3x1.kvs being the default.
To expand the cluster spin up new containers (lets say 3 more to have a 6 node 2 shard cluster) by running addnode.sh in the host
./addnode.sh 4
./addnode.sh 5
./addnode.sh 6

Remember when a new node is added, the entrypoint script ensures that the node is ready for nosql installation by running the makebootconfig script.
So all we now need to do is add these nodes into the cluster, you can take the sample script 4x1.kvs provided in /home/oracle/scripts as a base to expand the cluster.
So to expand the cluster from 3 nodes to 6 nodes do the following. 

1. spin up a client node (if you closed the default client node that docker-nosql.sh starts) or connect to a existing node (docker exec -it client or node1 bash)

2. cd /home/oracle/scripts

3. Create a new kvs file call it 6x2.kvs.

4. ./runScript.sh <admin node> <script without extension>
   
./runScript.sh node1 6x2
Copy the below statements into 6x2.kvs 

plan deploy-sn -znname "Houston" -port 5000 -wait -host node4
plan deploy-sn -znname "Houston" -port 5000 -wait -host node5
plan deploy-sn -znname "Houston" -port 5000 -wait -host node6

topology clone -current -name 6x2
topology redistribute -name 6x2 -pool AllStorageNodes
topology preview -name 6x2
plan deploy-topology -name 6x2 -wait

This will add nodes to the cluster and expand it.

# Exercises
There are sample scripts in /home/oracle/exercises which help in getting you started with creating a NoSQL Table (parent and child), inserting data and querying based on primary key or secondary index.

To execute the exercises do the following

1. connect to existing docker container or spin up a new container (docker exec or docker run)

2. cd /home/oracle/exercises

3. ./runScript.sh node1 createUserprofiletable.kvs

4. ./runScript.sh node1 insertData.kvs

5. ./getUserProfileData.sh node1 <userid> ex: ./getUserProfileData.sh node1 5

6. ./getUserProfileData.sh node1 -- to get all user profiles

7. ./runScript.sh node1 addIndexAdress.kvs -- create an index on zip field

8. ./getAddressDataByIndex.sh node1 95316 -- get all fields with zip = 95316

9. for more examples checkout $KVHOME/examples
