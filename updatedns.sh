DOCKER_DNS=`docker inspect -f '{{.NetworkSettings.IPAddress}}' dns`
echo $DOCKER_DNS
for containers in $(docker ps -q)
do
CONTAINER_NAME=`docker inspect -f '{{.Name}}' ${containers}`

if [ ${CONTAINER_NAME} = '/dns' ]; then
continue
fi
docker exec -t -i $containers /home/oracle/scripts/updatedns ${DOCKER_DNS}
done
docker ps
