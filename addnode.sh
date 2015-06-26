echo "adding node node${1}"
docker run -d --name node${1} -h node${1} -P --dns $(docker inspect -f '{{.NetworkSettings.IPAddress}}' dns)  --dns-search example.com nosql:1.0
